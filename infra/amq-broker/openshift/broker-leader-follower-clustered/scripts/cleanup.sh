#!/bin/bash
#
# Cleanup and Restore Script
#
# This script restores the AMQ broker environment to normal operation after testing.
# It removes mock pods and scales the operator back up to allow reconciliation.
#
# Usage:
#   ./cleanup.sh [NAMESPACE]
#
# Environment Variables:
#   NAMESPACE - OpenShift namespace (default: myproject)

set -e

NAMESPACE="${1:-${NAMESPACE:-myproject}}"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo "=============================================================================="
echo "AMQ BROKER ENVIRONMENT CLEANUP"
echo "=============================================================================="
echo ""
echo "Namespace: ${NAMESPACE}"
echo ""

# Remove mock pod if it exists
if oc get pod broker-ss-0 -n ${NAMESPACE} &>/dev/null; then
    POD_IMAGE=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || echo "")
    POD_COMMAND=$(oc get pod broker-ss-0 -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].command[0]}' 2>/dev/null || echo "")

    if [[ "$POD_COMMAND" == "sleep" ]]; then
        log_info "Removing mock broker-ss-0 pod..."
        oc delete pod broker-ss-0 -n ${NAMESPACE} --force --grace-period=0 2>/dev/null || true
        sleep 2
    else
        log_info "broker-ss-0 appears to be a real broker pod, leaving it alone"
    fi
else
    log_info "No broker-ss-0 pod found (may have already been cleaned up)"
fi

# Scale operator back up
log_info "Scaling AMQ Broker operator to 1 replica..."
oc scale deployment amq-broker-controller-manager --replicas=1 -n openshift-operators

# Wait a moment for operator to start
sleep 5

# Check operator status
OPERATOR_READY=$(oc get deployment amq-broker-controller-manager -n openshift-operators -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [[ "$OPERATOR_READY" == "1" ]]; then
    log_info "✅ Operator is ready"
else
    log_warn "Operator may still be starting (ready replicas: ${OPERATOR_READY})"
fi

echo ""
log_info "Cleanup complete. The operator will reconcile the environment."
echo ""
echo "Expected reconciliation:"
echo "  - StatefulSet will be recreated if missing"
echo "  - broker-ss-0 will be restarted if needed"
echo "  - System will return to normal HA configuration"
echo ""
echo "To check status:"
echo "  oc get pods -n ${NAMESPACE} -l ActiveMQArtemis=broker"
echo "  oc get statefulset -n ${NAMESPACE}"
echo ""
