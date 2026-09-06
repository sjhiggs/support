#!/bin/bash

cd "$(dirname "$0")/.."

CONNECTOR_NAME="oracle-inventory-connector"

echo "=========================================="
echo "Debezium Connect Failover Test"
echo "=========================================="
echo ""

# Function to show task distribution
show_status() {
    echo "Current Task Distribution:"
    curl -s http://localhost:8083/connectors/${CONNECTOR_NAME}/status 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f\"  Connector: {data['connector']['state']} on {data['connector']['worker_id']}\")
    for task in data['tasks']:
        print(f\"  Task {task['id']}: {task['state']} on {task['worker_id']}\")
except:
    print('  Unable to get status')
" 2>/dev/null
}

echo "Step 1: Initial State"
echo "---"
show_status
echo ""

echo "Press Enter to stop debezium-2 worker..."
read -r

echo ""
echo "Step 2: Stopping debezium-2..."
podman stop debezium-2
echo "  Worker stopped"
echo ""

echo "Waiting for rebalance (this takes 10-30 seconds)..."
sleep 15

echo ""
echo "Step 3: After Worker 2 Stopped"
echo "---"
show_status
echo ""
echo "Notice: Both tasks should now be on debezium-1:8083"
echo ""

echo "Press Enter to restart debezium-2..."
read -r

echo ""
echo "Step 4: Restarting debezium-2..."
podman start debezium-2
echo "  Worker starting..."
sleep 10

echo "Waiting for worker to join cluster and rebalance..."
sleep 15

echo ""
echo "Step 5: After Worker 2 Restarted"
echo "---"
show_status
echo ""
echo "Notice: Tasks should be redistributed across both workers"
echo ""

echo "=========================================="
echo "Failover Test Complete!"
echo "=========================================="
echo ""
echo "Key Observations:"
echo "  - When a worker fails, its tasks move to remaining workers"
echo "  - Rebalancing happens automatically (takes 10-30 seconds)"
echo "  - When worker rejoins, tasks are redistributed for load balancing"
echo "  - The connector continues to capture changes during failover"
echo ""
echo "You can verify continuous operation by:"
echo "  1. Running ./scripts/test-update.sh during failover"
echo "  2. Checking that all events still appear in Kafka topics"
echo ""
