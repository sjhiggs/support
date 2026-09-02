#!/bin/bash

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Stopping Kafka + Kroxylicious + HAProxy"
echo "=========================================="
echo ""

# Stop the stack
podman-compose down

echo ""
echo "✅ All services stopped"
echo ""
echo "To remove volumes as well:"
echo "  podman-compose down -v"
echo ""
