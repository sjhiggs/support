#!/bin/bash

# 1. Setup Base Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAFKA_PATH=${1:-$KAFKA_DIR}

# 2. Parse CLI parameters
while getopts "d:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka"; exit 1 ;;
  esac
done

if [ -z "$KAFKA_PATH" ]; then
    echo "Error: Kafka directory not specified."
    exit 1
fi

echo "--- Full Cluster Cleanup ---"

# 3. Stop Kafka first (Order matters!)
if [ -f "$SCRIPT_DIR/stop-cluster-kafka.sh" ]; then
    bash "$SCRIPT_DIR/stop-cluster-kafka.sh" -d "$KAFKA_PATH"
else
    echo "Warning: stop-cluster-kafka.sh not found, skipping..."
fi

# 4. Stop Zookeeper second
if [ -f "$SCRIPT_DIR/stop-cluster-zk.sh" ]; then
    bash "$SCRIPT_DIR/stop-cluster-zk.sh" -d "$KAFKA_PATH"
else
    echo "Warning: stop-cluster-zk.sh not found, skipping..."
fi

# 5. Wipe Data and Logs
echo "Removing temporary directories..."
# This removes all /tmp/zookeeper-X and /tmp/kafka-X folders
rm -rf /tmp/zookeeper-[0-2]
rm -rf /tmp/kafka-[0-2]

echo "  [✓] /tmp/zookeeper-[0-2] deleted"
echo "  [✓] /tmp/kafka-[0-2] deleted"

echo "-----------------------------------------------"
echo "Cleanup complete. Your environment is now fresh."
