#!/bin/bash

# 1. Setup
KAFKA_PATH=${1:-$KAFKA_DIR}
TOPIC_NAME="cluster-test-topic"
ZK_HOST="localhost:2181"

while getopts "d:t:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    t) TOPIC_NAME="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka [-t topic]"; exit 1 ;;
  esac
done

KAFKA_PATH="${KAFKA_PATH%/}"
ZK_SHELL="$KAFKA_PATH/bin/zookeeper-shell.sh"

extract_leader() {
    "$ZK_SHELL" $ZK_HOST get "/brokers/topics/$TOPIC_NAME/partitions/0/state" 2>/dev/null | grep -o '"leader":[0-9]*' | cut -d':' -f2
}

echo "==============================================="
echo "   KAFKA FAILOVER TEST: TOPIC $TOPIC_NAME"
echo "==============================================="

# 2. Identify Current Leader
ORIGINAL_LEADER=$(extract_leader)

if [ -z "$ORIGINAL_LEADER" ]; then
    echo "Error: Could not find leader for $TOPIC_NAME. Is the cluster running?"
    exit 1
fi

echo "[1/4] Current Leader for Partition 0 is Broker: $ORIGINAL_LEADER"

# 3. Find the PID of that specific broker
# We look for the config file in the process arguments to find the right PID
PID=$(ps ax | grep "kafka-$ORIGINAL_LEADER.properties" | grep -v grep | awk '{print $1}')

if [ -z "$PID" ]; then
    echo "Error: Could not find PID for Broker $ORIGINAL_LEADER"
    exit 1
fi

echo "[2/4] Killing Broker $ORIGINAL_LEADER (PID: $PID)..."
kill -9 "$PID"

# 4. Monitor ZooKeeper for Election
echo "[3/4] Watching ZooKeeper for Leader Election..."
NEW_LEADER=""
COUNT=0
while [ -z "$NEW_LEADER" ] || [ "$NEW_LEADER" == "$ORIGINAL_LEADER" ]; do
    sleep 1
    NEW_LEADER=$(extract_leader)
    COUNT=$((COUNT+1))
    echo "  > Waiting... (sec: $COUNT)"
    if [ $COUNT -gt 15 ]; then echo "Failover timed out!"; exit 1; fi
done

echo "-----------------------------------------------"
echo "SUCCESS: Failover Completed."
echo "New Leader for Partition 0: Broker $NEW_LEADER"
echo "-----------------------------------------------"

# 5. Show resulting ISR (In-Sync Replicas)
STATE=$("$ZK_SHELL" $ZK_HOST get "/brokers/topics/$TOPIC_NAME/partitions/0/state" 2>/dev/null | grep "^{")
echo "[4/4] Current ZK State: $STATE"
echo "==============================================="
echo "To recover, restart the cluster with: ./scripts/start-all.sh"
