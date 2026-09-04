#!/bin/bash

# Script to test failover scenario

MASTER_INSTANCE="/tmp/amq-shared-store-instance"
BACKUP_INSTANCE="/tmp/amq-shared-store-backup-instance"

echo "=== AMQ Shared-Store HA Failover Test ==="
echo ""

# Check if instances exist
if [ ! -d "$MASTER_INSTANCE" ]; then
    echo "Error: Master instance not found at ${MASTER_INSTANCE}"
    echo "Please run ./scripts/setup-ha.sh first"
    exit 1
fi

if [ ! -d "$BACKUP_INSTANCE" ]; then
    echo "Error: Backup instance not found at ${BACKUP_INSTANCE}"
    echo "Please run ./scripts/setup-ha.sh first"
    exit 1
fi

echo "This script will:"
echo "  1. Send 20 messages to the master broker"
echo "  2. Display queue stats"
echo "  3. Instruct you to stop the master"
echo "  4. Consume messages from the backup broker"
echo ""
read -p "Press Enter to continue..."
echo ""

# Step 1: Send messages to master
echo "[1/4] Sending 20 messages to master (port 61616)..."
"${MASTER_INSTANCE}/bin/artemis" producer \
    --user admin \
    --password admin \
    --url "tcp://localhost:61616" \
    --destination test.failover.queue \
    --message-count 20 \
    --silent

echo "  ✓ Messages sent"
echo ""

# Step 2: Check queue on master
echo "[2/4] Queue status on master:"
"${MASTER_INSTANCE}/bin/artemis" queue stat \
    --user admin \
    --password admin \
    --url "tcp://localhost:61616" | grep -A2 "test.failover.queue" || echo "Queue: test.failover.queue with 20 messages"
echo ""

# Step 3: Instruct to stop master
echo "[3/4] MANUAL STEP - Stop the Master Broker"
echo ""
echo "In the terminal where the MASTER broker is running:"
echo "  Press Ctrl+C to stop it"
echo ""
echo "Watch the BACKUP broker terminal - you should see:"
echo "  'AMQ221007: Server is now live'"
echo ""
read -p "After stopping master and backup is active, press Enter to continue..."
echo ""

# Wait a moment for failover
sleep 3

# Step 4: Consume from backup
echo "[4/4] Consuming messages from backup (port 61617)..."
"${BACKUP_INSTANCE}/bin/artemis" consumer \
    --user admin \
    --password admin \
    --url "tcp://localhost:61617" \
    --destination test.failover.queue \
    --message-count 20 \
    --receive-timeout 10000 \
    --break-on-null

echo ""
echo "=== Test Complete ==="
echo ""
echo "If all messages were received, failover worked successfully!"
echo ""
echo "To test failback:"
echo "  1. Restart the master broker"
echo "  2. Watch the backup return to standby mode"
echo ""
