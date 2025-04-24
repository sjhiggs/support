#!/bin/bash

readonly USAGE="
Usage: cert-client.sh [options]

Required:
  --cn=<string>          		the client CN name

Example:

cert-server.sh --cn=myserver 

"
OPTSPEC=":-:"
while getopts "$OPTSPEC" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        cn=*)
          cert_cn=${OPTARG#*=}
          ;;
        *)
          error "$USAGE"
          ;;
      esac;;
  esac
done

error() {
  echo "$@" 1>&2 && exit 1
}

shift $((OPTIND-1))

echo "cn: $cert_cn"

if [[ -z $cert_cn ]]; then
  error "$USAGE"
fi

echo "start of script..."

cd "$(dirname "$0")"

source ./env

openssl genpkey -algorithm rsa -out $data_dir/$certs_dir/$cert_cn.key -AES-256-CBC -pkeyopt rsa_keygen_bits:"$ca_key_bits" -pass pass:$ca_password

openssl req -new -key $data_dir/$certs_dir/$cert_cn.key -out $data_dir/$certs_dir/$cert_cn.csr -subj "$ca_dn_prefix/CN=$cert_cn" -passin pass:$ca_password 
openssl x509 -req -in $data_dir/$certs_dir/$cert_cn.csr -CA $data_dir/$ca_issuing_dir/ca.issuing.pem -CAkey $data_dir/$ca_issuing_dir/ca.issuing.key -out $data_dir/$certs_dir/$cert_cn.pem -days 3 -sha512 -copy_extensions copyall -passin pass:$ca_password
openssl rsa -in $data_dir/$certs_dir/$cert_cn.key -out $data_dir/$certs_dir/$cert_cn.key.decrypted -passin pass:$ca_password

