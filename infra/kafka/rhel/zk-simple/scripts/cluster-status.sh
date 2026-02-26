#!/bin/bash

# 1. Setup Base Paths
# Defaults to $KAFKA_DIR if no -d flag is provided
KAFKA_PATH=${1:-$KAFKA_DIR}
TOPIC_NAME="cluster-test-topic"
GROUP_ID="test-group"

# 2. Parse CLI parameters
while getopts "d:t:g:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    t) TOPIC_NAME="$OPTARG" ;;
    g) GROUP_ID="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka [-t topic] [-g group]"; exit 1 ;;
  esac
done

# Validation
if [ -z "$KAFKA_PATH" ]; then
    echo "Error: Kafka directory not specified. Use -d or set KAFKA_DIR."
    exit 1
fi

KAFKA_PATH="${KAFKA_PATH%/}"
BOOTSTRAP_SERVERS="localhost:9092,localhost:9093,localhost:9094"

echo "==============================================="
echo "   KAFKA CLUSTER STATUS REPORT"
echo "==============================================="
echo "Topic: $TOPIC_NAME"
echo "Group: $GROUP_ID"
echo "-----------------------------------------------"

# 3. Topic & Partition Detail
# Shows Leader, Replicas, and ISR for each partition
echo "--- Partition & Replication Status ---"
"$KAFKA_PATH/bin/kafka-topics.sh" --describe --topic "$TOPIC_NAME" \
    --bootstrap-server "$BOOTSTRAP_SERVERS"
echo ""

# 4. Message Count Calculation
# Uses the modern wrapper script to avoid ClassNotFound errors
echo "--- Message Metrics ---"
TOTAL_COUNT=$("$KAFKA_PATH/bin/kafka-get-offsets.sh" \
    --bootstrap-server "$BOOTSTRAP_SERVERS" \
    --topic "$TOPIC_NAME" --time -1 | awk -F ":" '{sum += $3} END {print sum}')

# Handle cases where the topic might not exist yet
if [ -z "$TOTAL_COUNT" ]; then TOTAL_COUNT=0; fi

echo "  Total Messages (Current): $TOTAL_COUNT"
echo ""

# 5. Consumer Group Lag
# Shows how far behind your consumer group is
echo "--- Consumer Group Lag ($GROUP_ID) ---"
"$KAFKA_PATH/bin/kafka-consumer-groups.sh" --bootstrap-server "$BOOTSTRAP_SERVERS" \
    --describe --group "$GROUP_ID" 2>/dev/null || echo "  [!] No active/stored offsets for group '$GROUP_ID'."
echo ""

# 6. Broker Health Check
# Queries Zookeeper to see which broker IDs are currently heartbeating
echo "--- Live Brokers in ZooKeeper ---"
ALIVE_IDS=$("$KAFKA_PATH/bin/zookeeper-shell.sh" localhost:2181 ls /brokers/ids 2>/dev/null | grep "\[")
echo "  Registered IDs: $ALIVE_IDS"

echo "==============================================="
