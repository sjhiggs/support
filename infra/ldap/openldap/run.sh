#!/bin/bash

# Configuration
CONTAINER_NAME="my-openldap-container"
DOMAIN="ldap.local"
ALT_DOMAIN="ldap2.local"
HOSTS_ENTRY="127.0.0.1 $DOMAIN $ALT_DOMAIN"

# Cleanup function to run on exit
cleanup() {
    echo -e "\n--- Cleaning up ---"
    sudo podman rm -f $CONTAINER_NAME
    # Remove the lines we added to /etc/hosts
    sudo sed -i "/$DOMAIN/d" /etc/hosts
    echo "Removed $DOMAIN from /etc/hosts"
}

# Trap interrupt signals (Ctrl+C) and exit
trap cleanup EXIT

# 1. Update /etc/hosts
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "Adding $DOMAIN to /etc/hosts..."
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
fi

# 2. Prepare Certificates
../../ca/scripts/create.sh
../../ca/scripts/cert-server.sh --cn=ldap --subject-alt-name="DNS:$DOMAIN" --subject-alt-name="DNS:$ALT_DOMAIN"

rm -rf /tmp/ldap-certs
mkdir -p /tmp/ldap-certs
cp /tmp/ca-data/certs/ldap.* /tmp/ldap-certs/
cat /tmp/ca-data/issuing/ca.issuing.pem /tmp/ca-data/ca/ca.pem > /tmp/ldap-certs/ca.pem

# 3. Pull and Run
podman pull osixia/openldap

sudo podman run -it --rm \
    --hostname "$DOMAIN" \
    --name "$CONTAINER_NAME" \
    --volume /tmp/ldap-certs:/container/service/slapd/assets/certs:z \
    --volume "$(pwd)/ldif/base.ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom/50-bootstrap.ldif:z" \
    --env LDAP_TLS_CRT_FILENAME=ldap.pem \
    --env LDAP_TLS_KEY_FILENAME=ldap.key.decrypted \
    --env LDAP_TLS_CA_CRT_FILENAME=ca.pem \
    --env LDAP_TLS_VERIFY_CLIENT=try \
    --env LDAP_DOMAIN=redhat.local \
    --sysctl net.ipv6.conf.all.disable_ipv6=1 \
    -p 389:389 \
    -p 636:636 \
    --privileged \
    osixia/openldap --copy-service
