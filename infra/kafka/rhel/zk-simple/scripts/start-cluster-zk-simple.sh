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

echo "--- Starting Zookeeper Cluster ---"

# 3. Loop through nodes 0, 1, and 2
for i in {0..2}; do
    # Log and Data share the same base node directory
    NODE_BASE="/tmp/zookeeper-$i"
    DATA_DIR="$NODE_BASE/data"
    CONF_FILE="$CONFIG_DIR/zookeeper-$i.properties"
    
    echo "Node $i:"

    # Ensure directories exist
    mkdir -p "$DATA_DIR"
    echo "$i" > "$DATA_DIR/myid"

    if [ -f "$CONF_FILE" ]; then
        EXEC_SCRIPT="$KAFKA_PATH/bin/zookeeper-server-start.sh"
        
        # 4. Redirect Logs
        # LOG_DIR tells the script where to put the .out and log files
        export LOG_DIR="$NODE_BASE/logs"
        
        echo "  [>] Starting with LOG_DIR=$LOG_DIR"
        "$EXEC_SCRIPT" -daemon "$CONF_FILE"
        
        sleep 2
    else
        echo "  [!] Error: Config $CONF_FILE not found."
    fi
done

echo "-----------------------------------------------"
echo "Done. Logs are located in /tmp/zookeeper-[0-2]/"
