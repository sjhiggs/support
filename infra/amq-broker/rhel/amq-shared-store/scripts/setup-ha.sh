#!/bin/bash

# Script to set up both master and backup instances for shared-store HA
#
# Usage: ./setup-ha.sh [VERSION]
#   VERSION: Artemis version to install (default: 2.56.0)
#
# Example:
#   ./setup-ha.sh           # Uses default version 2.56.0
#   ./setup-ha.sh 2.55.0    # Uses specific version 2.55.0

set -e

SUBPROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTEMIS_VERSION="${1:-2.56.0}"  # Default to 2.56.0, can be overridden with first argument
TMP_DIR="/tmp/artemis_setup"
INSTALL_DIR="${TMP_DIR}/apache-artemis-${ARTEMIS_VERSION}"
MASTER_INSTANCE="/tmp/amq-shared-store-instance"
BACKUP_INSTANCE="/tmp/amq-shared-store-backup-instance"
SHARED_DATA="/tmp/shared-data"

echo "=== AMQ Broker Shared-Store HA Setup ==="
echo "Using Artemis version: ${ARTEMIS_VERSION}"
echo ""

# Step 1: Create shared storage directory
echo "[1/4] Creating shared storage directory at ${SHARED_DATA}..."
mkdir -p "${SHARED_DATA}"/{journal,bindings,paging,large-messages}
echo "  ✓ Shared storage created"
echo ""

# Step 2: Install master using the standard install script
echo "[2/4] Installing master broker instance..."
cd "${SUBPROJECT_DIR}"
../scripts/install.sh --version "${ARTEMIS_VERSION}"
echo "  ✓ Master instance created at ${MASTER_INSTANCE}"
echo ""

# Step 3: Create backup instance
echo "[3/4] Creating backup broker instance..."

# Check if Artemis is installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: Artemis installation not found at ${INSTALL_DIR}"
    echo "Please run ../scripts/install.sh first"
    exit 1
fi

# Remove existing backup instance
rm -rf "$BACKUP_INSTANCE"

# Create backup instance
"${INSTALL_DIR}/bin/artemis" create "$BACKUP_INSTANCE" \
    --user admin \
    --password admin \
    --allow-anonymous \
    --silent

# Copy backup configuration files
cp "${SUBPROJECT_DIR}/etc/broker-backup.xml" "${BACKUP_INSTANCE}/etc/broker.xml"
cp "${SUBPROJECT_DIR}/etc/bootstrap-backup.xml" "${BACKUP_INSTANCE}/etc/bootstrap.xml"
cp "${SUBPROJECT_DIR}/etc/login.config" "${BACKUP_INSTANCE}/etc/"
cp "${SUBPROJECT_DIR}/etc/artemis-users.properties" "${BACKUP_INSTANCE}/etc/"
cp "${SUBPROJECT_DIR}/etc/artemis-roles.properties" "${BACKUP_INSTANCE}/etc/"

echo "  ✓ Backup instance created at ${BACKUP_INSTANCE}"
echo ""

# Step 4: Summary
echo "[4/4] Setup complete!"
echo ""
echo "=== Next Steps ==="
echo ""
echo "To start the MASTER broker:"
echo "  ${MASTER_INSTANCE}/bin/artemis run"
echo ""
echo "To start the BACKUP broker (in another terminal):"
echo "  ${BACKUP_INSTANCE}/bin/artemis run"
echo ""
echo "Web Consoles:"
echo "  Master:  http://localhost:8161/console"
echo "  Backup:  http://localhost:8162/console (when active)"
echo ""
echo "Credentials: admin/admin"
echo ""
echo "=== Test Failover ==="
echo ""
echo "1. Start both brokers"
echo "2. Send messages to master (port 61616)"
echo "3. Stop master with Ctrl+C"
echo "4. Backup should activate automatically"
echo "5. Consume messages from backup (port 61617)"
echo ""
