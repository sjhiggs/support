#!/bin/bash

# 1. Setup Base Paths
# Get Kafka path from 1st argument or Environment Variable
KAFKA_PATH=${1:-$KAFKA_DIR}
TOPIC_NAME="cluster-test-topic"
GROUP_ID="test-group"  # Added persistent group ID

# 2. Handle CLI parameters
while getopts "d:t:g:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    t) TOPIC_NAME="$OPTARG" ;;
    g) GROUP_ID="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka [-t topic] [-g group]"; exit 1 ;;
  esac
done

if [ -z "$KAFKA_PATH" ]; then
    echo "Error: Kafka directory not specified."
    exit 1
fi

KAFKA_PATH="${KAFKA_PATH%/}"
BOOTSTRAP_SERVERS="localhost:9092,localhost:9093,localhost:9094"

echo "==============================================="
echo "   KAFKA CLUSTER VERIFICATION TEST"
echo "==============================================="

# 3. Create a Topic (3 partitions, 3 replicas)
echo "[1/3] Creating topic: $TOPIC_NAME"
"$KAFKA_PATH/bin/kafka-topics.sh" --create --topic "$TOPIC_NAME" \
    --bootstrap-server "$BOOTSTRAP_SERVERS" \
    --partitions 3 --replication-factor 3 \
    --if-not-exists

# 4. Produce Messages
echo "[2/3] Sending messages to $TOPIC_NAME..."
cat <<EOF | "$KAFKA_PATH/bin/kafka-console-producer.sh" --topic "$TOPIC_NAME" --bootstrap-server "$BOOTSTRAP_SERVERS"
Hello from Node 0
Message for Node 1
Data for Node 2
Kafka Cluster is Working!
EOF
echo "  [✓] 4 messages sent."

# 5. Consume Messages with a persistent Group ID
# Using --group ensures the offset is committed to __consumer_offsets
echo "[3/3] Consuming messages using group: $GROUP_ID..."
"$KAFKA_PATH/bin/kafka-console-consumer.sh" --topic "$TOPIC_NAME" \
    --bootstrap-server "$BOOTSTRAP_SERVERS" \
    --from-beginning \
    --group "$GROUP_ID" \
    --max-messages 4 \
    --timeout-ms 10000

echo "-----------------------------------------------"
echo "Verification complete. Group '$GROUP_ID' is now active."
echo "You can now run: ./scripts/cluster-status.sh -g $GROUP_ID"
echo "==============================================="
