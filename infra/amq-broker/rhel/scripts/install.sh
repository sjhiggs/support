#!/bin/bash

# --- Path Resolution ---
# Because the script is executed from the subproject directory, 
# $PWD represents the subproject root (e.g., .../rhel/amq-ldap)
SUBPROJECT_DIR="$PWD"
SUBPROJECT_NAME=$(basename "$SUBPROJECT_DIR")

# --- Defaults ---
ARTEMIS_VERSION="2.56.0"
TMP_DIR="/tmp/artemis_setup"
LOCAL_ETC_SOURCE="${SUBPROJECT_DIR}/etc"

# Dynamically name the instance based on the subproject to avoid collisions
if [ "$SUBPROJECT_NAME" = "amq-live-cluster" ]; then
    INSTANCE_DIR="/tmp/broker1-instance"
else
    INSTANCE_DIR="/tmp/${SUBPROJECT_NAME}-instance"
fi

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) ARTEMIS_VERSION="$2"; shift ;;
        --help|-h) 
            echo "Usage: $0 [--version 2.x.x]"
            exit 0 
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

INSTALL_DIR="${TMP_DIR}/apache-artemis-${ARTEMIS_VERSION}"
TARBALL="${TMP_DIR}/artemis_${ARTEMIS_VERSION}.tar.gz"

# Determine download URL based on version
# Versions >= 2.45.0 use new path: /artemis/artemis/
# Versions <  2.45.0 use old path: /activemq/activemq-artemis/
if [[ "${ARTEMIS_VERSION}" =~ ^2\.([4][5-9]|[5-9][0-9])\..*$ ]] || [[ "${ARTEMIS_VERSION}" =~ ^[3-9]\. ]]; then
    # New path (2.45.0+)
    MIRROR_URL="https://downloads.apache.org/artemis/artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
    ARCHIVE_URL="https://archive.apache.org/dist/artemis/artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
else
    # Old path (< 2.45.0)
    MIRROR_URL="https://dlcdn.apache.org/activemq/activemq-artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
    ARCHIVE_URL="https://archive.apache.org/dist/activemq/activemq-artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
fi

# --- Execution ---

mkdir -p "$TMP_DIR"

# 1. Skip download if already present
if [ -d "$INSTALL_DIR" ]; then
    echo "Found existing Artemis installation at ${INSTALL_DIR}. Skipping download."
else
    echo "Artemis not found locally. Downloading version ${ARTEMIS_VERSION}..."

    # Try current mirror first
    if curl -Lf "$MIRROR_URL" -o "$TARBALL" 2>/dev/null; then
        echo "Downloaded from current mirror."
    elif curl -Lf "$ARCHIVE_URL" -o "$TARBALL" 2>/dev/null; then
        echo "Downloaded from archive."
    else
        echo "Error: Failed to download Artemis version ${ARTEMIS_VERSION}."
        echo "Tried:"
        echo "  - ${MIRROR_URL}"
        echo "  - ${ARCHIVE_URL}"
        exit 1
    fi

    echo "Unpacking Artemis..."
    tar -xzf "$TARBALL" -C "$TMP_DIR"
    rm "$TARBALL"
fi

# 2. Always Re-initialize the Instance Directory
echo "Re-initializing instance at ${INSTANCE_DIR}..."
rm -rf "$INSTANCE_DIR"

"${INSTALL_DIR}/bin/artemis" create "$INSTANCE_DIR" \
    --user admin \
    --password admin \
    --allow-anonymous \
    --silent

# 3. Copy custom etc directory
if [ -d "$LOCAL_ETC_SOURCE" ]; then
    echo "Applying configuration from ${LOCAL_ETC_SOURCE}..."

    if [ "$SUBPROJECT_NAME" = "amq-live-cluster" ]; then
        cp -v "$LOCAL_ETC_SOURCE"/broker1.xml "${INSTANCE_DIR}/etc/broker.xml"
        cp -v "$LOCAL_ETC_SOURCE"/bootstrap1.xml "${INSTANCE_DIR}/etc/bootstrap.xml"
        cp -v "$LOCAL_ETC_SOURCE"/login.config "${INSTANCE_DIR}/etc/"
        cp -v "$LOCAL_ETC_SOURCE"/artemis-users.properties "${INSTANCE_DIR}/etc/"
        cp -v "$LOCAL_ETC_SOURCE"/artemis-roles.properties "${INSTANCE_DIR}/etc/"
    else
        cp -rv "$LOCAL_ETC_SOURCE"/* "${INSTANCE_DIR}/etc/"
    fi
else
    echo "Error: Directory ${LOCAL_ETC_SOURCE} does not exist."
    echo "Make sure you are running this script from the root of a subproject."
    exit 1
fi

echo "---"
echo "Setup complete! Instance: ${INSTANCE_DIR}"
