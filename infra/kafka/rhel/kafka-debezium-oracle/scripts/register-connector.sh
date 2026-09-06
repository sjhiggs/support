#!/bin/bash

cd "$(dirname "$0")/.."

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
CONNECTOR_CONFIG="config/debezium/register-oracle.json"

echo "=========================================="
echo "Registering Oracle Debezium Connector"
echo "=========================================="
echo ""

# Check if Debezium Connect is running
if ! curl -s "${CONNECT_URL}" > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to Debezium Connect at ${CONNECT_URL}"
    echo "Make sure the services are running: ./scripts/podman-start.sh"
    exit 1
fi

# Check if connector config exists
if [ ! -f "${CONNECTOR_CONFIG}" ]; then
    echo "ERROR: Connector configuration not found: ${CONNECTOR_CONFIG}"
    exit 1
fi

echo "Registering connector at ${CONNECT_URL}/connectors..."
echo ""

# Register the connector
response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    --data @"${CONNECTOR_CONFIG}" \
    "${CONNECT_URL}/connectors")

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
    echo "SUCCESS! Connector registered."
    echo ""
    echo "Connector Details:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    echo ""

    # Wait a moment for connector to initialize
    sleep 3

    # Check connector status
    echo ""
    echo "Connector Status:"
    connector_name=$(echo "$body" | grep -o '"name":"[^"]*' | cut -d'"' -f4)
    curl -s "${CONNECT_URL}/connectors/${connector_name}/status" | python3 -m json.tool

    echo ""
    echo "=========================================="
    echo "Connector Registered Successfully!"
    echo "=========================================="
    echo ""
    echo "Available Topics (wait a few seconds for initial snapshot):"
    echo "  oracle.DEBEZIUM.PRODUCTS"
    echo "  oracle.DEBEZIUM.PRODUCTS_ON_HAND"
    echo "  oracle.DEBEZIUM.CUSTOMERS"
    echo "  oracle.DEBEZIUM.ORDERS"
    echo ""
    echo "List all topics:"
    echo "  podman exec kafka-0 /opt/kafka/bin/kafka-topics.sh \\"
    echo "    --bootstrap-server localhost:9092 --list"
    echo ""
    echo "Consume events from products table:"
    echo "  podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
    echo "    --bootstrap-server localhost:9092 \\"
    echo "    --topic oracle.DEBEZIUM.PRODUCTS \\"
    echo "    --from-beginning"
    echo ""
    echo "Test database changes:"
    echo "  ./scripts/test-update.sh"
    echo ""
else
    echo "ERROR! Failed to register connector."
    echo "HTTP Status: $http_code"
    echo ""
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    echo ""

    # Show existing connectors
    echo "Existing connectors:"
    curl -s "${CONNECT_URL}/connectors" | python3 -m json.tool
    echo ""
    exit 1
fi
