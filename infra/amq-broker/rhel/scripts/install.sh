#!/bin/bash

# --- Path Resolution ---
# Because the script is executed from the subproject directory, 
# $PWD represents the subproject root (e.g., .../rhel/amq-ldap)
SUBPROJECT_DIR="$PWD"
SUBPROJECT_NAME=$(basename "$SUBPROJECT_DIR")

# --- Defaults ---
ARTEMIS_VERSION="2.32.0"
TMP_DIR="/tmp/artemis_setup"
# Dynamically name the instance based on the subproject to avoid collisions
INSTANCE_DIR="/tmp/${SUBPROJECT_NAME}-instance" 
LOCAL_ETC_SOURCE="${SUBPROJECT_DIR}/etc"

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
DOWNLOAD_URL="https://archive.apache.org/dist/activemq/activemq-artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz"
TARBALL="${TMP_DIR}/artemis_${ARTEMIS_VERSION}.tar.gz"

# --- Execution ---

mkdir -p "$TMP_DIR"

# 1. Skip download if already present
if [ -d "$INSTALL_DIR" ]; then
    echo "Found existing Artemis installation at ${INSTALL_DIR}. Skipping download."
else
    echo "Artemis not found locally. Downloading..."
    if ! curl -Lf "$DOWNLOAD_URL" -o "$TARBALL"; then
        echo "Error: Failed to download Artemis version ${ARTEMIS_VERSION}."
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
    cp -rv "$LOCAL_ETC_SOURCE"/* "${INSTANCE_DIR}/etc/"
else
    echo "Error: Directory ${LOCAL_ETC_SOURCE} does not exist."
    echo "Make sure you are running this script from the root of a subproject."
    exit 1
fi

echo "---"
echo "Setup complete! Instance: ${INSTANCE_DIR}"
