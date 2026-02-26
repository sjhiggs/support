#!/bin/bash

# 1. Setup Base Path
KAFKA_PATH=$KAFKA_DIR

while getopts "d:" opt; do
  case $opt in
    d) KAFKA_PATH="$OPTARG" ;;
    *) echo "Usage: $0 -d /path/to/kafka"; exit 1 ;;
  esac
done

KAFKA_PATH="${KAFKA_PATH%/}"
ZK_SHELL="$KAFKA_PATH/bin/zookeeper-shell.sh"

if [ ! -f "$ZK_SHELL" ]; then
    echo "Error: Kafka path invalid. Could not find $ZK_SHELL"
    exit 1
fi

ZK_HOST="localhost:2181"

echo "==============================================="
echo "   KAFKA METADATA & LEADER COORDINATION"
echo "==============================================="

# Helper to clean JSON output - pulls the line starting with { and strips prefixes
extract_json() {
    "$ZK_SHELL" $ZK_HOST get "$1" 2>/dev/null | grep "^{"
}

# 2. Cluster & Controller Info
echo -n "Cluster ID: "
CLUSTER_JSON=$(extract_json /cluster/id)
echo "$CLUSTER_JSON" | grep -o '"id":"[^"]*"' | cut -d'"' -f4

CONTROLLER_JSON=$(extract_json /controller)
CONTROLLER_ID=$(echo "$CONTROLLER_JSON" | grep -o '"brokerid":[0-9]*' | cut -d':' -f2)
echo "Current Controller: Broker $CONTROLLER_ID"

# 3. Partition Leader Coordination
echo -e "\n--- Partition Leader States (from ZK) ---"

# Get topics and strip the [ ] and commas using a safer method
TOPIC_RAW=$("$ZK_SHELL" $ZK_HOST ls /brokers/topics 2>/dev/null | grep "^\[")
TOPICS=$(echo "$TOPIC_RAW" | sed 's/[][]//g; s/,/ /g')

for topic in $TOPICS; do
    echo "Topic: $topic"
    
    # Get partitions for this topic
    PART_RAW=$("$ZK_SHELL" $ZK_HOST ls /brokers/topics/$topic/partitions 2>/dev/null | grep "^\[")
    PARTITIONS=$(echo "$PART_RAW" | sed 's/[][]//g; s/,/ /g')
    
    for p in $PARTITIONS; do
        # The 'state' znode is where the Controller writes the leader election result
        STATE_JSON=$(extract_json "/brokers/topics/$topic/partitions/$p/state")
        
        if [ -n "$STATE_JSON" ]; then
            LEADER=$(echo "$STATE_JSON" | grep -o '"leader":[0-9]*' | cut -d':' -f2)
            ISR=$(echo "$STATE_JSON" | grep -o '"isr":\[[^]]*\]' | cut -d':' -f2)
            echo "  > Partition $p | Leader: Broker $LEADER | ISR: $ISR"
        fi
    done
done

# 4. Active Broker Check
echo -e "\n--- Live Broker IDs ---"
"$ZK_SHELL" $ZK_HOST ls /brokers/ids 2>/dev/null | grep "^\["

echo "==============================================="
