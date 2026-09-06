#!/bin/bash

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Starting Kafka + Debezium + Oracle Stack"
echo "Using: Podman Compose"
echo "=========================================="
echo ""

# Check if podman-compose is available
if ! command -v podman-compose &> /dev/null; then
    echo "ERROR: podman-compose not found"
    echo ""
    echo "Install with:"
    echo "  sudo dnf install podman-compose        # Fedora/RHEL"
    echo "  pip3 install --user podman-compose     # Alternative"
    echo ""
    exit 1
fi

# Load version configuration
if [ -f versions.env ]; then
    echo "Loading versions from versions.env..."
    export $(grep -v '^#' versions.env | xargs)
    echo "  Kafka: ${KAFKA_VERSION}"
    echo "  Debezium: ${DEBEZIUM_VERSION}"
    echo "  Oracle: ${ORACLE_VERSION}"
    echo "  Oracle JDBC: ${ORACLE_JDBC_VERSION}"
    echo ""
fi

# Start the stack
echo "Starting containers..."
podman-compose up -d --build

echo ""
echo "Waiting for services to initialize..."
echo "  - Kafka cluster (3 nodes)..."
sleep 15

echo "  - Oracle database (this may take 1-2 minutes)..."
echo "  - Debezium workers (2 nodes in distributed mode)..."
sleep 30

# Check status
echo ""
echo "Container Status:"
podman-compose ps

echo ""
echo "Waiting for Debezium Connect to be ready..."
max_wait=120
elapsed=0
while [ $elapsed -lt $max_wait ]; do
    if curl -s http://localhost:8083/ > /dev/null 2>&1; then
        echo "Debezium Connect Worker 1 is ready!"
        break
    fi
    echo "  Still waiting... ($elapsed seconds)"
    sleep 10
    elapsed=$((elapsed + 10))
done

if curl -s http://localhost:8084/ > /dev/null 2>&1; then
    echo "Debezium Connect Worker 2 is ready!"
fi

echo ""
echo "=========================================="
echo "Services Started!"
echo "=========================================="
echo ""
echo "Components:"
echo "  Kafka Cluster:        kafka-0:9092, kafka-1:9093, kafka-2:9094"
echo "  Oracle Database:      localhost:1521 (XEPDB1)"
echo "    - User: debezium / Password: dbz"
echo "    - SYS Password: oracle"
echo "  Debezium Worker 1:    http://localhost:8083"
echo "  Debezium Worker 2:    http://localhost:8084"
echo ""
echo "Next Steps:"
echo "  1. Register Oracle connector:"
echo "     ./scripts/register-connector.sh"
echo ""
echo "  2. Test database changes:"
echo "     ./scripts/test-update.sh"
echo ""
echo "  3. View captured events:"
echo "     podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "       --bootstrap-server localhost:9092 \\"
echo "       --topic oracle.DEBEZIUM.PRODUCTS \\"
echo "       --from-beginning"
echo ""
echo "View logs:"
echo "  podman-compose logs -f"
echo "  podman-compose logs -f debezium-1"
echo "  podman-compose logs -f oracle"
echo ""
echo "Stop services:"
echo "  ./scripts/podman-stop.sh"
echo ""
