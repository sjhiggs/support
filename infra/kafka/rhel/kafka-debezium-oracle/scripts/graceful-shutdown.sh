#!/bin/bash

cd "$(dirname "$0")/.."

WORKER="${1:-debezium-2}"

echo "=========================================="
echo "Graceful Worker Shutdown Best Practices"
echo "=========================================="
echo ""

echo "Worker to shutdown: ${WORKER}"
echo ""

# Show current state
echo "Current State:"
curl -s http://localhost:8083/connectors/oracle-inventory-connector/status 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for task in data['tasks']:
        print(f\"  Task {task['id']}: {task['state']} on {task['worker_id']}\")
except:
    pass
" 2>/dev/null

echo ""
echo "Shutdown Options:"
echo ""
echo "1. GRACEFUL (Recommended)"
echo "   podman stop ${WORKER}"
echo "   - Sends SIGTERM signal"
echo "   - Worker shuts down cleanly (30-60 seconds)"
echo "   - Tasks commit offsets and stop gracefully"
echo "   - Worker leaves the group cleanly"
echo "   - Other workers rebalance automatically"
echo ""

echo "2. FORCEFUL (Not Recommended)"
echo "   podman kill ${WORKER}"
echo "   - Sends SIGKILL signal"
echo "   - Immediate termination"
echo "   - Tasks don't commit final offsets cleanly"
echo "   - Cluster waits for heartbeat timeout (~10s) to detect failure"
echo "   - Small risk of duplicate events on recovery"
echo ""

echo "3. DELETE CONNECTOR FIRST (Unnecessary)"
echo "   curl -X DELETE http://localhost:8083/connectors/oracle-inventory-connector"
echo "   podman stop ${WORKER}"
echo "   - Stops all data capture"
echo "   - Requires manual re-registration after restart"
echo "   - Only needed if permanently removing the connector"
echo ""

echo "Press Enter to perform GRACEFUL shutdown of ${WORKER}..."
read -r

echo ""
echo "Performing graceful shutdown..."
echo "Command: podman stop ${WORKER}"
echo ""

# Time the shutdown
start_time=$(date +%s)
podman stop ${WORKER}
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Worker stopped gracefully in ${duration} seconds"
echo ""

echo "Waiting for cluster to detect and rebalance..."
sleep 15

echo ""
echo "New Task Distribution:"
curl -s http://localhost:8083/connectors/oracle-inventory-connector/status 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for task in data['tasks']:
        print(f\"  Task {task['id']}: {task['state']} on {task['worker_id']}\")
except:
    print('  Unable to get status')
" 2>/dev/null

echo ""
echo "=========================================="
echo "Best Practices Summary"
echo "=========================================="
echo ""
echo "✓ DO:"
echo "  - Use 'podman stop' for graceful shutdown"
echo "  - Let distributed mode handle rebalancing automatically"
echo "  - Monitor connector status during/after shutdown"
echo "  - Verify tasks are running after rebalance"
echo ""
echo "✗ DON'T:"
echo "  - Use 'podman kill' unless absolutely necessary"
echo "  - Delete connector for routine worker maintenance"
echo "  - Assume immediate rebalancing (allow 10-30 seconds)"
echo ""
echo "To restart the worker:"
echo "  podman start ${WORKER}"
echo ""
