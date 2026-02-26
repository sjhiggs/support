#!/bin/bash

# 1. Setup Base Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAFKA_PATH=$KAFKA_DIR

# 2. Parse CLI parameters
while getopts "d:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka"; exit 1 ;;
  esac
done

if [ -z "$KAFKA_PATH" ]; then
    echo "Error: Kafka directory not specified. Use -d or set KAFKA_DIR."
    exit 1
fi

echo "==============================================="
echo "   STARTING FULL KAFKA CLUSTER STACK           "
echo "==============================================="

# 3. Start ZooKeeper Ensemble
if [ -f "$SCRIPT_DIR/start-cluster-zk-simple.sh" ]; then
    echo "[Step 1/2] Launching ZooKeeper Ensemble..."
    bash "$SCRIPT_DIR/start-cluster-zk-simple.sh" -d "$KAFKA_PATH"
else
    echo "Error: ZooKeeper start script not found!"
    exit 1
fi

# 4. The "Quorum Wait" 
# ZooKeeper needs time to perform leader election (ZAB protocol)
echo "Waiting 10 seconds for ZooKeeper Quorum to stabilize..."
sleep 10

# 5. Start Kafka Brokers
if [ -f "$SCRIPT_DIR/start-cluster-kafka.sh" ]; then
    echo "[Step 2/2] Launching Kafka Brokers..."
    bash "$SCRIPT_DIR/start-cluster-kafka.sh" -d "$KAFKA_PATH"
else
    echo "Error: Kafka start script not found!"
    exit 1
fi

echo "==============================================="
echo "   CLUSTER STARTUP COMPLETE                    "
echo "==============================================="
echo "Run 'jps' to verify 3 QuorumPeerMain and 3 Kafka processes."
