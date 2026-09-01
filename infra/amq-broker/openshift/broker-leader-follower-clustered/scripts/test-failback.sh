#!/bin/bash
#
# Failback Test Script
#
# This script tests the shared-store HA failback mechanism. It expects the backup
# to be currently LIVE (from running test-failover.sh first) and tests that the
# primary can reclaim its role when it returns.
#
# The test verifies that when a new primary process starts (new pod/process),
# it can successfully join the cluster, request the file lock, and trigger
# failback. This is the normal production failback scenario.
#
# Prerequisites:
#   - Backup should be LIVE (Ready: true)
#   - Primary should be mock pod or missing
#   - Run test-failover.sh first to set up this state
#
# Usage:
#   ./test-failback.sh [NAMESPACE] [TIMEOUT]
#
# Environment Variables:
#   NAMESPACE - OpenShift namespace (default: myproject)
#   TIMEOUT   - Monitoring timeout in seconds (default: 120)

set -e

NAMESPACE="${1:-${NAMESPACE:-myproject}}"
TIMEOUT="${2:-${TIMEOUT:-120}}"
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
echo "AMQ BROKER SHARED-STORE HA FAILBACK TEST"
echo "=============================================================================="
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Timeout:   ${TIMEOUT} seconds"
echo ""
echo "This test will:"
echo "  1. Verify backup is currently LIVE"
echo "  2. Remove mock broker-ss-0 pod"
echo "  3. Scale operator back up"
echo "  4. Monitor for primary to reclaim its role"
echo "  5. Monitor for backup to return to standby"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Pre-flight checks
log_step "Running pre-flight checks..."

if ! oc get namespace ${NAMESPACE} &>/dev/null; then
    log_error "Namespace ${NAMESPACE} not found"
    exit 1
fi

if ! oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} &>/dev/null; then
    log_error "broker-cluster-follower-ss-0 pod not found in namespace ${NAMESPACE}"
    exit 1
fi

# Check backup is LIVE (Ready: true)
BACKUP_READY=$(oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
if [[ "$BACKUP_READY" != "true" ]]; then
    log_error "Backup is not LIVE (Ready: ${BACKUP_READY})"
    echo ""
    echo "Expected: Backup should be Ready: true (currently LIVE)"
    echo "Run test-failover.sh first to activate the backup"
    exit 1
fi

log_info "Backup is LIVE (Ready: true) ✓"

# Check if broker-ss-0 is a mock pod
if oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; then
    POD_COMMAND=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].command[0]}' 2>/dev/null || echo "")
    if [[ "$POD_COMMAND" != "sleep" ]]; then
        log_warn "broker-ss-0 exists but doesn't appear to be a mock pod"
        log_warn "This may interfere with the test"
    else
        log_info "Mock broker-ss-0 pod found ✓"
    fi
fi

log_info "Pre-flight checks passed"
echo ""

# Step 1: Remove mock pod
log_step "Step 1: Removing mock broker-ss-0 pod..."
if oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; then
    oc delete pod broker-ss-0 -n ${NAMESPACE} --force --grace-period=0

    log_info "Waiting for pod to be fully removed..."
    while oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; do
        sleep 1
    done
    log_info "Mock pod removed"
else
    log_info "broker-ss-0 not found, skipping deletion"
fi

# Step 2: Scale operator back up
log_step "Step 2: Scaling operator back to 1 replica..."
oc scale deployment amq-broker-controller-manager --replicas=1 -n openshift-operators
sleep 5

log_info "Waiting for operator to be ready..."
for i in {1..30}; do
    OPERATOR_READY=$(oc get deployment amq-broker-controller-manager -n openshift-operators -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [[ "$OPERATOR_READY" == "1" ]]; then
        log_info "Operator is ready ✓"
        break
    fi
    sleep 2
done

log_info "Waiting for broker-ss-0 to be created by operator..."
for i in {1..60}; do
    if oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; then
        POD_PHASE=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.phase}')
        if [[ "$POD_PHASE" == "Running" ]]; then
            log_info "broker-ss-0 is running ✓"
            break
        fi
    fi
    sleep 2
done

# Step 3: Monitor for failback
log_step "Step 3: Monitoring for failback (${TIMEOUT} seconds)..."
echo ""
echo "Expected sequence:"
echo "  → Operator reconciles and creates broker-ss-0"
echo "  → Primary starts and requests file lock"
echo "  → Backup detects primary return"
echo "  → Backup relinquishes lock (with failbackDelay=0)"
echo "  → Primary becomes LIVE"
echo "  → Backup returns to standby"
echo ""

PRIMARY_LIVE=false
BACKUP_STANDBY=false
START_TIME=$(date +%s)

for i in $(seq 1 $((TIMEOUT / 5))); do
    ELAPSED=$(($(date +%s) - START_TIME))
    TIMESTAMP=$(date +%H:%M:%S)

    # Check pod status
    PRIMARY_STATUS=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    PRIMARY_READY=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    BACKUP_READY=$(oc get pod broker-cluster-follower-ss-0 -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "unknown")

    echo "[$TIMESTAMP] Check $i/$((TIMEOUT / 5)) (${ELAPSED}s elapsed)"
    echo "  Primary (broker-ss-0):                 Status=$PRIMARY_STATUS, Ready=$PRIMARY_READY"
    echo "  Backup (broker-cluster-follower-ss-0): Ready=$BACKUP_READY"

    # Check if primary is live
    if [[ "$PRIMARY_READY" == "true" ]] && [[ "$PRIMARY_LIVE" == "false" ]]; then
        if oc logs broker-ss-0 -n ${NAMESPACE} 2>/dev/null | grep -q "AMQ221007: Server is now active"; then
            log_info "✓ Primary is LIVE"
            PRIMARY_LIVE=true
        fi
    fi

    # Check if backup returned to standby
    # Note: Ready=false (0/1) is the CORRECT state for standby backup
    if [[ "$BACKUP_READY" == "false" ]] && [[ "$BACKUP_STANDBY" == "false" ]]; then
        # Backup pod being Not Ready indicates it's in standby (not serving traffic)
        log_info "✓ Backup is in standby (Ready=false is correct)"
        BACKUP_STANDBY=true
    fi

    # Check if failback is complete
    if [[ "$PRIMARY_LIVE" == "true" ]] && [[ "$BACKUP_STANDBY" == "true" ]]; then
        echo ""
        log_info "✅ FAILBACK COMPLETED!"
        break
    fi

    sleep 5
done

echo ""
echo "=============================================================================="
echo "TEST RESULTS"
echo "=============================================================================="
echo ""

if [[ "$PRIMARY_LIVE" == "true" ]] && [[ "$BACKUP_STANDBY" == "true" ]]; then
    log_info "✅ FAILBACK TEST PASSED"
    echo ""
    echo "The primary successfully reclaimed its role and the backup returned to standby."
    echo ""
    echo "Failback timeline:"
    echo ""
    echo "Primary logs:"
    oc logs broker-ss-0 -n ${NAMESPACE} 2>/dev/null | grep -E "Waiting.*primary lock|AMQ221007" | tail -5
    echo ""
    echo "Backup logs:"
    oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} | grep -E "$(date -u --date='3 minutes ago' '+%Y-%m-%d %H:%M')" | grep -E "relinquish|shutdown|AMQ221109" | tail -5
    echo ""
    echo "Final pod status:"
    oc get pods -n ${NAMESPACE} -l 'ActiveMQArtemis in (broker,broker-cluster-follower)'
elif [[ "$PRIMARY_LIVE" == "true" ]]; then
    log_warn "⚠️  PARTIAL SUCCESS"
    echo ""
    echo "Primary is LIVE but backup status unclear (Ready: ${BACKUP_READY})"
    echo "Backup may still be transitioning to standby."
    echo ""
    echo "Check backup logs:"
    oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} --tail=20
elif [[ "$BACKUP_STANDBY" == "true" ]]; then
    log_warn "⚠️  PARTIAL SUCCESS"
    echo ""
    echo "Backup returned to standby but primary not confirmed LIVE (Ready: ${PRIMARY_READY})"
    echo "Primary may still be starting."
    echo ""
    echo "Check primary status:"
    oc get pod broker-ss-0 -n ${NAMESPACE}
else
    log_warn "⚠️  FAILBACK NOT OBSERVED WITHIN ${TIMEOUT} SECONDS"
    echo ""
    echo "Current state:"
    echo "  Primary LIVE:    $PRIMARY_LIVE"
    echo "  Backup standby:  $BACKUP_STANDBY"
    echo ""
    echo "Possible causes:"
    echo "  - Timeout too short (try TIMEOUT=180)"
    echo "  - Configuration issue with failbackDelay"
    echo "  - Operator reconciliation taking longer than expected"
    echo ""
    echo "Pod status:"
    oc get pods -n ${NAMESPACE} -l 'ActiveMQArtemis in (broker,broker-cluster-follower)'
    echo ""
    echo "Primary logs:"
    oc logs broker-ss-0 -n ${NAMESPACE} --tail=20 2>/dev/null || echo "  (pod not available)"
    echo ""
    echo "Backup logs:"
    oc logs broker-cluster-follower-ss-0 -n ${NAMESPACE} --tail=20
fi

echo ""
log_info "Test complete. System should now be in normal HA configuration."
echo ""
