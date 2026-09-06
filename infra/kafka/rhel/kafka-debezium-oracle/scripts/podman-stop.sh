#!/bin/bash

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Stopping Kafka + Debezium + Oracle Stack"
echo "=========================================="
echo ""

# Stop and remove containers
echo "Stopping containers..."
podman-compose down

echo ""
echo "=========================================="
echo "Services Stopped!"
echo "=========================================="
echo ""
echo "To remove all data volumes as well:"
echo "  podman-compose down -v"
echo ""
echo "To start again:"
echo "  ./scripts/podman-start.sh"
echo ""
