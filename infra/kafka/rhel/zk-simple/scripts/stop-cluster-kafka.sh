#!/bin/bash

# 1. Setup Base Path
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

STOP_SCRIPT="${KAFKA_PATH%/}/bin/kafka-server-stop.sh"

if [ ! -x "$STOP_SCRIPT" ]; then
    echo "Error: Shutdown script not found at $STOP_SCRIPT"
    exit 1
fi

# 4. Shutdown Logic
echo "Attempting to stop all Kafka brokers..."

# The official script sends a SIGTERM to all processes matching the Kafka class
bash "$STOP_SCRIPT"

# 5. Verification
echo "Verifying shutdown..."
sleep 3
REMAINING=$(jps | grep -c "Kafka")

if [ "$REMAINING" -eq 0 ]; then
    echo "  [✓] All Kafka brokers stopped successfully."
else
    echo "  [!] $REMAINING broker(s) still running. Forcing shutdown..."
    # Targets the specific Kafka class name
    pkill -9 -f "kafka\.Kafka"
    echo "  [✓] Cleanup complete."
fi
