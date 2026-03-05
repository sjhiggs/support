#!/bin/bash

# 1. Setup Base Paths
# Get the absolute path of the directory where THIS script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Move up one level to the project base directory
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 2. Handle KAFKA_DIR (The location of the Kafka binaries)
KAFKA_PATH=${1:-$KAFKA_DIR}

if [ -z "$KAFKA_PATH" ]; then
    echo "Error: KAFKA_DIR is not set and no CLI parameter was provided."
    echo "Usage: $0 /path/to/kafka-binaries"
    exit 1
fi

# 3. Define the Configs Subfolder
CONFIG_DIR="$PROJECT_ROOT/config"

echo "Project Root: $PROJECT_ROOT"
echo "Config Directory: $CONFIG_DIR"

# 4. Loop through nodes 0, 1, and 2
for i in {0..2}; do
    DATA_DIR="/tmp/zookeeper-$i/data"
    CONF_FILE="$CONFIG_DIR/zookeeper-$i.properties"
    
    echo "-----------------------------------------------"
    echo "Processing Instance $i..."

    # Create Data Directory and myid
    mkdir -p "$DATA_DIR"
    echo "$i" > "$DATA_DIR/myid"
    echo "  [✓] Initialized $DATA_DIR with myid: $i"

    # 5. Start Instance using the Kafka binaries
    if [ -f "$CONF_FILE" ]; then
        echo "  [>] Starting ZooKeeper using config: $CONF_FILE"
        # Run the start script from the provided Kafka path
        "$KAFKA_PATH/bin/zookeeper-server-start.sh" -daemon "$CONF_FILE"
        sleep 2 
    else
        echo "  [!] Error: Configuration file NOT FOUND at $CONF_FILE"
    fi
done

echo "-----------------------------------------------"
echo "Startup sequence complete."
