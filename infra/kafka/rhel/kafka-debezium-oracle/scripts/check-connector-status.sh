#!/bin/bash

cd "$(dirname "$0")/.."

CONNECTOR_NAME="${1:-oracle-inventory-connector}"
WORKER1_URL="http://localhost:8083"
WORKER2_URL="http://localhost:8084"

echo "=========================================="
echo "Connector Status & Task Distribution"
echo "=========================================="
echo ""

# Check connector status
echo "Connector: ${CONNECTOR_NAME}"
echo ""

echo "--- Overall Status ---"
curl -s "${WORKER1_URL}/connectors/${CONNECTOR_NAME}/status" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Connector State: {data['connector']['state']}\")
print(f\"Worker ID: {data['connector']['worker_id']}\")
print(f\"Tasks: {len(data['tasks'])}\")
print()
print('Task Assignments:')
for task in data['tasks']:
    print(f\"  Task {task['id']}: {task['state']} on {task['worker_id']}\")
" 2>/dev/null

echo ""
echo "--- Detailed Task Info ---"
curl -s "${WORKER1_URL}/connectors/${CONNECTOR_NAME}/tasks" | python3 -m json.tool

echo ""
echo "=========================================="
echo "Worker Information"
echo "=========================================="
echo ""

echo "--- Worker 1 (port 8083) ---"
curl -s "${WORKER1_URL}/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Version: {data['version']}\")
print(f\"Commit: {data['commit']}\")
" 2>/dev/null

# Check which connectors this worker knows about
echo "Connectors on Worker 1:"
curl -s "${WORKER1_URL}/connectors" | python3 -m json.tool

echo ""
echo "--- Worker 2 (port 8084) ---"
curl -s "${WORKER2_URL}/" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Version: {data['version']}\")
print(f\"Commit: {data['commit']}\")
" 2>/dev/null

echo "Connectors on Worker 2:"
curl -s "${WORKER2_URL}/connectors" | python3 -m json.tool

echo ""
echo "=========================================="
echo "Cluster State"
echo "=========================================="
echo ""

# In distributed mode, all workers share the same connector state
# but tasks are distributed across workers
echo "Note: In distributed mode, both workers see the same connectors,"
echo "but tasks are distributed across the cluster for load balancing."
echo ""
