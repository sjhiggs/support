#!/bin/bash

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Starting Kafka + Kroxylicious + HAProxy"
echo "Using: Podman Compose"
echo "=========================================="
echo ""

# Check if podman-compose is available
if ! command -v podman-compose &> /dev/null; then
    echo "❌ ERROR: podman-compose not found"
    echo ""
    echo "Install with:"
    echo "  sudo dnf install podman-compose        # Fedora/RHEL"
    echo "  pip3 install --user podman-compose     # Alternative"
    echo ""
    exit 1
fi

# Start the stack
echo "Starting containers..."
podman-compose up -d

echo ""
echo "Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "Container Status:"
podman-compose ps

echo ""
echo "=========================================="
echo "Services Started!"
echo "=========================================="
echo ""
echo "Client Connection:"
echo "  bootstrap.servers=localhost:9095"
echo ""
echo "Monitoring:"
echo "  HAProxy Stats: http://localhost:8404/stats"
echo ""
echo "View logs:"
echo "  podman-compose logs -f"
echo ""
echo "Stop services:"
echo "  ./scripts/podman-stop.sh"
echo "  OR: podman-compose down"
echo ""
