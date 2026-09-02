#!/bin/bash

cd "$(dirname "$0")/.."

KAFKA_VERSION=${KAFKA_VERSION:-4.3.1}
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION

echo "=========================================="
echo "Testing Kafka Cluster via Podman"
echo "=========================================="
echo ""

# Check if Kafka tools are available
if [ ! -f "$KAFKA_DIR/bin/kafka-topics.sh" ]; then
    echo "Kafka tools not found. Downloading..."
    export KAFKA_VERSION=$KAFKA_VERSION
    ../scripts/kafka-get.sh --kafka-version=$KAFKA_VERSION
fi

# Check if services are running
if ! podman-compose ps | grep -q "Up"; then
    echo "❌ ERROR: Services not running"
    echo ""
    echo "Start services first:"
    echo "  ./scripts/podman-start.sh"
    echo ""
    exit 1
fi

echo "1. Creating test topic..."
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server proxy.local:9095 \
    --create --topic podman-test \
    --partitions 3 \
    --replication-factor 3 \
    --if-not-exists

echo ""
echo "2. Listing topics..."
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server proxy.local:9095 --list

echo ""
echo "3. Describing topic..."
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server proxy.local:9095 \
    --describe --topic podman-test

echo ""
echo "4. Producing test messages..."
echo -e "message-1\nmessage-2\nmessage-3" | \
    $KAFKA_DIR/bin/kafka-console-producer.sh \
    --bootstrap-server proxy.local:9095 \
    --topic podman-test

echo ""
echo "5. Consuming messages..."
$KAFKA_DIR/bin/kafka-console-consumer.sh \
    --bootstrap-server proxy.local:9095 \
    --topic podman-test \
    --from-beginning \
    --timeout-ms 5000

echo ""
echo "=========================================="
echo "✅ Test Complete!"
echo "=========================================="
echo ""
echo "Check HAProxy stats:"
echo "  curl http://localhost:8404/stats"
echo ""
echo "View logs:"
echo "  podman-compose logs kroxylicious"
echo "  podman-compose logs haproxy"
echo ""
