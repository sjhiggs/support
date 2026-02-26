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

# 3. Validation
if [ -z "$KAFKA_PATH" ]; then
    echo "Error: Kafka directory not specified (set KAFKA_DIR or use -d)."
    exit 1
fi

STOP_SCRIPT="${KAFKA_PATH%/}/bin/zookeeper-server-stop.sh"

if [ ! -x "$STOP_SCRIPT" ]; then
    echo "Error: Shutdown script not found at $STOP_SCRIPT"
    exit 1
fi

# 4. Shutdown Logic
echo "Attempting to stop all ZooKeeper instances..."

# The Kafka stop script looks for 'QuorumPeerMain' and sends a SIGTERM
# Since all 3 instances run under that name, this usually stops all of them.
bash "$STOP_SCRIPT"

# 5. Verification
sleep 2
REMAINING=$(jps | grep -c "QuorumPeerMain")

if [ "$REMAINING" -eq 0 ]; then
    echo "  [✓] All ZooKeeper nodes stopped successfully."
else
    echo "  [!] $REMAINING node(s) still running. Forcing shutdown..."
    pkill -9 -f "QuorumPeerMain"
    echo "  [✓] Cleanup complete."
fi
