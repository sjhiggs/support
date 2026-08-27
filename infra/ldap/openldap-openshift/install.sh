#!/bin/bash
set -e

NAMESPACE="openldap"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOMAIN="openldap.${NAMESPACE}.svc.cluster.local"

echo "=== OpenLDAP on OpenShift ==="

# 1. Create project
if oc get project "$NAMESPACE" &>/dev/null; then
    echo "Project '$NAMESPACE' already exists, switching to it..."
    oc project "$NAMESPACE"
else
    echo "Creating project '$NAMESPACE'..."
    oc new-project "$NAMESPACE"
fi

# 2. Grant anyuid SCC (osixia/openldap requires root)
echo "Granting anyuid SCC to default service account..."
oc adm policy add-scc-to-user anyuid -z default -n "$NAMESPACE"

# 3. Generate TLS certificates using shared CA scripts
echo "Generating TLS certificates..."
"${SCRIPT_DIR}/../../ca/scripts/create.sh"
"${SCRIPT_DIR}/../../ca/scripts/cert-server.sh" \
    --cn=ldap \
    --subject-alt-name="DNS:${DOMAIN}" \
    --subject-alt-name="DNS:openldap" \
    --subject-alt-name="DNS:openldap.${NAMESPACE}" \
    --subject-alt-name="DNS:localhost"

# 4. Create TLS secret
echo "Creating TLS secret..."
cat /tmp/ca-data/issuing/ca.issuing.pem /tmp/ca-data/ca/ca.pem > /tmp/ca-data/certs/ca.pem

oc delete secret openldap-tls -n "$NAMESPACE" --ignore-not-found
oc create secret generic openldap-tls \
    --from-file=ldap.pem=/tmp/ca-data/certs/ldap.pem \
    --from-file=ldap.key.decrypted=/tmp/ca-data/certs/ldap.key.decrypted \
    --from-file=ca.pem=/tmp/ca-data/certs/ca.pem \
    -n "$NAMESPACE"

# 5. Apply manifests
echo "Applying OpenLDAP manifests..."
oc apply -f "${SCRIPT_DIR}/yaml/" -n "$NAMESPACE"

# 6. Wait for rollout
echo "Waiting for deployment to be ready..."
oc rollout status deployment/openldap -n "$NAMESPACE" --timeout=120s

echo ""
echo "=== OpenLDAP is ready ==="
echo ""
echo "To access from your local machine, run:"
echo "  oc port-forward svc/openldap -n $NAMESPACE 389:389 636:636"
echo ""
echo "Then test with:"
echo "  ldapsearch -x -H ldaps://localhost -b dc=redhat,dc=local -D \"cn=admin,dc=redhat,dc=local\" -w admin"
echo ""
echo "Note: point your ~/.ldaprc at the CA cert for ldaps to work:"
echo "  TLS_CACERT /tmp/ca-data/certs/ca.pem"
echo ""
echo "To clean up:"
echo "  oc delete project $NAMESPACE"
