#!/bin/bash

# --- Helper Functions ---
error() {
  echo -e "ERROR: $1" >&2
  exit 1
}

readonly USAGE="
Usage: cert-server.sh [options]

Required:
  --cn=<string>                The server Common Name (CN)

Optional:
  --subject-alt-name=<string>  Value for SAN (can be used multiple times)
                               Example: --subject-alt-name=\"DNS:site.com\" --subject-alt-name=\"IP:1.1.1.1\"
  --days=<int>                 Certificate validity (default: 3)
"

# --- Argument Parsing ---
OPTSPEC=":-:"
cert_days=3
san_list=() # Array to hold multiple SANs

while getopts "$OPTSPEC" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        cn=*) cert_cn=${OPTARG#*=} ;;
        subject-alt-name=*) san_list+=("${OPTARG#*=}") ;; # Append to array
        days=*) cert_days=${OPTARG#*=} ;;
        *) error "Unknown option --${OPTARG}\n$USAGE" ;;
      esac;;
    *) error "$USAGE" ;;
  esac
done

[[ -z $cert_cn ]] && error "Missing required --cn parameter.\n$USAGE"

# --- Environment & Paths ---
cd "$(dirname "$0")"
[[ -f "./env" ]] && source ./env || error "Configuration file './env' not found."

CERT_BASE="$data_dir/$certs_dir/$cert_cn"
CA_DIR="$data_dir/$ca_issuing_dir"
mkdir -p "$(dirname "$CERT_BASE")"

# --- Process SAN Array ---
# Join array elements with a comma
final_san_string=$(IFS=,; echo "${san_list[*]}")

# 

# --- Execution ---

echo "Generating key for $cert_cn..."
openssl genpkey -algorithm rsa \
    -out "${CERT_BASE}.key" \
    -aes-256-cbc \
    -pkeyopt rsa_keygen_bits:"${ca_key_bits:-2048}" \
    -pass "pass:$ca_password"

# Prepare CSR Arguments
REQ_ARGS=(-new -key "${CERT_BASE}.key" -out "${CERT_BASE}.csr" -subj "$ca_dn_prefix/CN=$cert_cn" -passin "pass:$ca_password")

if [[ ${#san_list[@]} -gt 0 ]]; then
    echo "Adding SANs: $final_san_string"
    # We wrap the SAN string for the OpenSSL extension
    REQ_ARGS+=(-addext "subjectAltName = $final_san_string")
fi

echo "Creating CSR..."
openssl req "${REQ_ARGS[@]}"

echo "Signing Certificate..."
openssl x509 -req \
    -in "${CERT_BASE}.csr" \
    -CA "$CA_DIR/ca.issuing.pem" \
    -CAkey "$CA_DIR/ca.issuing.key" \
    -CAcreateserial \
    -out "${CERT_BASE}.pem" \
    -days "$cert_days" \
    -sha512 \
    -copy_extensions copyall \
    -passin "pass:$ca_password"

# Optional: Decrypt key for specific legacy services
openssl rsa -in "${CERT_BASE}.key" -out "${CERT_BASE}.key.decrypted" -passin "pass:$ca_password"

echo "Done. Certificate and keys generated at: ${CERT_BASE}.*"
