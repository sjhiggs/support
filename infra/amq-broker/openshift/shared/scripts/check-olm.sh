#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Error: OCP version is required."
    echo "Usage: $0 <version>"
    echo "Example: $0 4.16"
    exit 1
fi

OCP_VERSION=$1
INDEX_IMAGE="registry.redhat.io/redhat/redhat-operator-index:v$OCP_VERSION"

echo "Extracting catalog for OCP version: $OCP_VERSION..."

# Remove image to ensure fresh data; ignore error if image doesn't exist
podman image rm "$INDEX_IMAGE" 2>/dev/null || true

# Execute the render and filter
podman run --rm "$INDEX_IMAGE" render /var/lib/iib/_hidden/do.not.edit.db | \
jq --arg pkg "amq-broker" 'select(.schema == "olm.channel" and (.package | startswith($pkg)))'
