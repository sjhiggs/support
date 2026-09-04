#!/bin/bash

set -e

SUBPROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTEMIS_VERSION="${1:-2.56.0}"
TMP_DIR="/tmp/artemis_setup"
INSTALL_DIR="${TMP_DIR}/apache-artemis-${ARTEMIS_VERSION}"
BROKER1_INSTANCE="/tmp/broker1-instance"
BROKER2_INSTANCE="/tmp/broker2-instance"

echo "=== AMQ Broker Live Cluster Setup ==="
echo "Using Artemis version: ${ARTEMIS_VERSION}"
echo ""

echo "[1/3] Creating broker1 data directory..."
mkdir -p /tmp/broker1-data/{journal,bindings,paging,large-messages}
echo "  ✓ Broker1 data created"
echo ""

echo "[2/3] Installing broker1 instance..."
cd "${SUBPROJECT_DIR}"
../scripts/install.sh --version "${ARTEMIS_VERSION}"
echo "  ✓ Broker1 instance created at ${BROKER1_INSTANCE}"
echo ""

echo "[3/3] Creating broker2 instance..."

if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: Artemis installation not found at ${INSTALL_DIR}"
    exit 1
fi

mkdir -p /tmp/broker2-data/{journal,bindings,paging,large-messages}

rm -rf "$BROKER2_INSTANCE"

"${INSTALL_DIR}/bin/artemis" create "$BROKER2_INSTANCE" \
    --user admin \
    --password admin \
    --allow-anonymous \
    --silent

cp "${SUBPROJECT_DIR}/etc/broker2.xml" "${BROKER2_INSTANCE}/etc/broker.xml"
cp "${SUBPROJECT_DIR}/etc/bootstrap2.xml" "${BROKER2_INSTANCE}/etc/bootstrap.xml"
cp "${SUBPROJECT_DIR}/etc/login.config" "${BROKER2_INSTANCE}/etc/"
cp "${SUBPROJECT_DIR}/etc/artemis-users.properties" "${BROKER2_INSTANCE}/etc/"
cp "${SUBPROJECT_DIR}/etc/artemis-roles.properties" "${BROKER2_INSTANCE}/etc/"

echo "  ✓ Broker2 instance created at ${BROKER2_INSTANCE}"
echo ""

echo "=== Setup complete! ==="
echo ""
echo "Start broker1: ${BROKER1_INSTANCE}/bin/artemis run"
echo "Start broker2: ${BROKER2_INSTANCE}/bin/artemis run"
echo ""
echo "Web Consoles:"
echo "  Broker1: http://localhost:8161/console"
echo "  Broker2: http://localhost:8162/console"
echo ""
echo "Credentials: admin/admin"
echo ""
