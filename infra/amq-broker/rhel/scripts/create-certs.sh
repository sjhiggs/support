#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Dynamic Path Resolution ---
# Find the absolute directory where this script is located, regardless of where it's executed from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Configuration Variables ---
# Anchor the external scripts directory to this script's location
SCRIPTS_DIR="$SCRIPT_DIR/../../../ca/scripts"

CA_DATA_DIR="/tmp/ca-data"
CA_DIR="$CA_DATA_DIR/ca"
ISSUING_DIR="$CA_DATA_DIR/issuing"
CERTS_DIR="$CA_DATA_DIR/certs"

# New directory for the application
APP_DIR="/tmp/myapp-certs" 
PASSWORD="foobar"

# --- 1. Preparation ---
echo "Creating application directory at $APP_DIR..."
mkdir -p "$APP_DIR"

# --- 2. Generate Certificates ---
echo "Generating certificates using scripts in $SCRIPTS_DIR..."
"$SCRIPTS_DIR/create.sh"
"$SCRIPTS_DIR/cert-server.sh" --cn=myserver --subject-alt-name="DNS:127.0.0.1,DNS:localhost"
"$SCRIPTS_DIR/cert-client.sh" --cn=myuser

# --- 3. Create Combined PEMs ---
echo "Combining PEM files..."
cat "$CERTS_DIR/myuser.pem" "$ISSUING_DIR/ca.issuing.pem" > "$CERTS_DIR/myuser.combined.pem"
cat "$CERTS_DIR/myserver.pem" "$ISSUING_DIR/ca.issuing.pem" > "$CERTS_DIR/myserver.combined.pem"

# --- 4. Create Truststore ---
echo "Building truststore..."
openssl pkcs12 -export -nokeys -in "$CA_DIR/ca.pem" -out "$CERTS_DIR/truststore.p12" -passout "pass:$PASSWORD"
keytool -import -file "$CA_DIR/ca.pem" -keystore "$CERTS_DIR/truststore.p12" -storetype PKCS12 -storepass "$PASSWORD" -noprompt

# --- 5. Create Keystores ---
echo "Building keystores..."
openssl pkcs12 -export -name myServer -noiter -nomaciter \
  -in "$CERTS_DIR/myserver.combined.pem" \
  -inkey "$CERTS_DIR/myserver.key" \
  -out "$CERTS_DIR/myserver.p12" \
  -passin "pass:$PASSWORD" -passout "pass:$PASSWORD"

openssl pkcs12 -export \
  -in "$CERTS_DIR/myuser.combined.pem" \
  -inkey "$CERTS_DIR/myuser.key" \
  -out "$CERTS_DIR/myuser.p12" \
  -passin "pass:$PASSWORD" -passout "pass:$PASSWORD"

# --- 6. Apply Permissions ---
echo "Applying read permissions..."
chmod -R a+r "$CA_DATA_DIR"

# --- 7. Move to Application Directory ---
echo "Moving keystores and truststore to $APP_DIR..."
mv "$CERTS_DIR/truststore.p12" "$APP_DIR/"
mv "$CERTS_DIR/myserver.p12" "$APP_DIR/"
mv "$CERTS_DIR/myuser.p12" "$APP_DIR/"

# Ensure the new app directory and its contents are also readable
chmod -R a+r "$APP_DIR"

echo "Done! Certificates and stores are ready in $APP_DIR."
