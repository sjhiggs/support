#!/bin/bash
#
# Failover Test Script
#
# This script tests the shared-store HA failover mechanism by creating a mock
# broker-ss-0 pod (no broker process) to prevent Kubernetes auto-restart,
# allowing observation of backup activation to LIVE status.
#
# Usage:
#   ./test-failover.sh [NAMESPACE] [TIMEOUT]
#
# Environment Variables:
#   NAMESPACE - OpenShift namespace (default: myproject)
#   TIMEOUT   - Monitoring timeout in seconds (default: 90)

set -e

NAMESPACE="${1:-${NAMESPACE:-myproject}}"
TIMEOUT="${2:-${TIMEOUT:-90}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "=============================================================================="
echo "AMQ BROKER SHARED-STORE HA FAILOVER TEST"
echo "=============================================================================="
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Timeout:   ${TIMEOUT} seconds"
echo ""
echo "This test will:"
echo "  1. Scale down the operator (prevent auto-reconciliation)"
echo "  2. Delete the StatefulSet (keep pods running)"
echo "  3. Delete broker-ss-0 pod"
echo "  4. Create mock broker-ss-0 (maintains DNS, no broker process)"
echo "  5. Monitor backup for activation to LIVE"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Cleanup function
cleanup_on_exit() {
    if [[ "$KEEP_ENV" != "true" ]]; then
        echo ""
        log_info "Running cleanup..."
        ${SCRIPT_DIR}/cleanup.sh ${NAMESPACE}
    else
        echo ""
        log_warn "KEEP_ENV=true, skipping cleanup"
        log_warn "Run './cleanup.sh ${NAMESPACE}' manually when ready"
    fi
}

# Set trap to cleanup on exit
trap cleanup_on_exit EXIT

# Pre-flight checks
log_step "Running pre-flight checks..."

if ! oc get namespace ${NAMESPACE} &>/dev/null; then
    log_error "Namespace ${NAMESPACE} not found"
    exit 1
fi

if ! oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; then
    log_error "broker-ss-0 pod not found in namespace ${NAMESPACE}"
    exit 1
fi

if ! oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} &>/dev/null; then
    log_error "broker-cluster-follower-ss-0 pod not found in namespace ${NAMESPACE}"
    exit 1
fi

# Check backup is in standby
BACKUP_READY=$(oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
if [[ "$BACKUP_READY" != "false" ]]; then
    log_warn "Backup appears to be READY (may already be live). Expected: standby (0/1 Ready)"
fi

log_info "Pre-flight checks passed"
echo ""

# Step 1: Scale operator to 0
log_step "Step 1: Scaling operator to 0 replicas..."
oc scale deployment amq-broker-controller-manager --replicas=0 -n openshift-operators
sleep 5

# Step 2: Delete StatefulSet (keep pods)
log_step "Step 2: Deleting StatefulSet (keeping pods)..."
if oc get statefulset broker-ss -n ${NAMESPACE} &>/dev/null; then
    oc delete statefulset broker-ss --cascade=orphan -n ${NAMESPACE}
    sleep 2
else
    log_warn "StatefulSet broker-ss not found (may already be deleted)"
fi

# Step 3: Delete broker-ss-0
log_step "Step 3: Deleting broker-ss-0 pod..."
oc delete pod broker-ss-0 -n ${NAMESPACE}

log_info "Waiting for broker-ss-0 to terminate..."
while oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; do
    sleep 1
done
log_info "broker-ss-0 terminated"

# Step 4: Create mock pod
log_step "Step 4: Creating mock broker-ss-0 pod..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broker-ss-0
  namespace: ${NAMESPACE}
  labels:
    ActiveMQArtemis: broker
    application: broker-app
    statefulset.kubernetes.io/pod-name: broker-ss-0
spec:
  hostname: broker-ss-0
  subdomain: broker-hdls-svc
  containers:
  - name: broker-container
    image: registry.redhat.io/amq7/amq-broker-rhel9:7.13
    command: ["sleep", "infinity"]
    volumeMounts:
    - name: broker-data
      mountPath: /opt/amq/data
  volumes:
  - name: broker-data
    persistentVolumeClaim:
      claimName: myvol-broker-ss-0
EOF

log_info "Waiting for mock pod to start..."
while [[ $(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.phase}' 2>/dev/null) != "Running" ]]; do
    sleep 1
done
log_info "Mock pod is running (DNS maintained, no broker process)"
echo ""

# Step 5: Monitor backup for activation
log_step "Step 5: Monitoring backup for activation (${TIMEOUT} seconds)..."
echo ""
echo "Expected sequence:"
echo "  → Backup detects: 'nodeID...is closing'"
echo "  → Backup detects: 'Connection closure...server shutdown'"
echo "  → Backup activates: 'AMQ221010: Backup Server is now active'"
echo "  → Acceptor starts: 'Started EPOLL Acceptor at...61616'"
echo ""

ACTIVATED=false
START_TIME=$(date +%s)
SHUTDOWN_DETECTED=false

for i in $(seq 1 $((TIMEOUT / 5))); do
    ELAPSED=$(($(date +%s) - START_TIME))
    TIMESTAMP=$(date +%H:%M:%S)
    READY=$(oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "unknown")

    echo "[$TIMESTAMP] Check $i/$((TIMEOUT / 5)) (${ELAPSED}s elapsed) - Ready: $READY"

    # Check for shutdown detection
    if [[ "$SHUTDOWN_DETECTED" == "false" ]]; then
        if oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} --since=6s 2>/dev/null | grep -q "is closing\|server shutdown"; then
            log_info "✓ Primary shutdown detected"
            SHUTDOWN_DETECTED=true
        fi
    fi

    # Check for activation message
    if oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} --since=6s 2>/dev/null | grep -q "AMQ221010: Backup Server is now active"; then
        echo ""
        log_info "✅ BACKUP ACTIVATED TO LIVE!"
        echo ""
        echo "Activation timeline:"
        oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} | grep -E "$(date -u --date='2 minutes ago' '+%Y-%m-%d %H:%M')" | grep -E "closing|shutdown|Deploying|Acceptor.*61616|now active" | tail -10
        ACTIVATED=true
        break
    fi

    sleep 5
done

echo ""
echo "=============================================================================="
echo "TEST RESULTS"
echo "=============================================================================="
echo ""

if [[ "$ACTIVATED" == "true" ]]; then
    log_info "✅ FAILOVER TEST PASSED"
    echo ""
    echo "The backup successfully activated to LIVE when the primary didn't return."
    echo ""
    echo "Current state:"
    echo "  - Mock pod (broker-ss-0): Running with sleep command (no broker)"
    echo "  - Backup (broker-cluster-follower-ss-0): LIVE and accepting connections"
    echo ""
    echo "Backup status:"
    oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE}
    echo ""
    log_info "Test complete! Use test-failback.sh to test failback behavior."
    echo ""
    read -p "Keep environment for failback test? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        KEEP_ENV=true
        log_info "Environment preserved. Run './test-failback.sh ${NAMESPACE}' next."
    fi
else
    log_warn "⚠️  FAILOVER NOT OBSERVED WITHIN ${TIMEOUT} SECONDS"
    echo ""
    echo "Possible causes:"
    echo "  - Timeout too short (try TIMEOUT=120)"
    echo "  - Configuration issue"
    echo "  - Network connectivity problem"
    echo ""
    echo "Last 30 lines of backup logs:"
    oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} --tail=30
    echo ""
    echo "Backup pod status:"
    oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE}
fi

echo ""
