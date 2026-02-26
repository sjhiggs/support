#!/bin/bash

# 1. Setup Base Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"

# 2. Handle KAFKA_DIR
KAFKA_PATH=$KAFKA_DIR
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

KAFKA_PATH="${KAFKA_PATH%/}"

echo "--- Starting Zero-Indexed Kafka Cluster (0-2) ---"

# 3. Loop through brokers 0, 1, and 2
for i in {0..2}; do
    NODE_BASE="/tmp/kafka-$i"
    # Create the data directory (where Kafka stores actual messages)
    mkdir -p "$NODE_BASE/data"
    
    CONF_FILE="$CONFIG_DIR/kafka-$i.properties"
    
    echo "Broker ID $i:"

    if [ -f "$CONF_FILE" ]; then
        EXEC_SCRIPT="$KAFKA_PATH/bin/kafka-server-start.sh"
        
        # LOG_DIR tells Kafka where to put its application logs (kafka.out, etc.)
        export LOG_DIR="$NODE_BASE/logs"
        
        echo "  [>] Launching daemon with LOG_DIR=$LOG_DIR"
        "$EXEC_SCRIPT" -daemon "$CONF_FILE"
        
        # Give it a moment to initialize before starting the next one
        sleep 3
    else
        echo "  [!] Error: Config $CONF_FILE not found."
    fi
done

echo "-----------------------------------------------"
echo "Verifying Broker Registration..."
sleep 2
# Check Zookeeper to see which IDs are registered
$KAFKA_PATH/bin/zookeeper-shell.sh localhost:2181 ls /brokers/ids | grep "\["
