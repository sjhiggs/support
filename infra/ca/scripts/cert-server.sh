#!/bin/bash


readonly USAGE="
Usage: cert-server.sh [options]

Required:
  --cn=<string>          		the server CN name

Optional:
  --subject-alt-name=<string>		the value for the subject alt name extension

Example:

cert-server.sh --cn=myserver --subject-alt-name=\"DNS: myserver.test.com\"

"
OPTSPEC=":-:"
while getopts "$OPTSPEC" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        cn=*)
          cert_cn=${OPTARG#*=}
          ;;
        subject-alt-name=*)
          cert_subject_alt_name=${OPTARG#*=}
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
echo "subject alt name: $cert_subject_alt_name"

if [[ -z $cert_cn ]]; then
  error "$USAGE"
fi

echo "start of script..."

cd "$(dirname "$0")"

source ./env

openssl genpkey -algorithm rsa -out $data_dir/$certs_dir/$cert_cn.key -AES-256-CBC -pkeyopt rsa_keygen_bits:"$ca_key_bits" -pass pass:$ca_password

if [[ -z $cert_subject_alt_name ]]; then
   echo "creating cert with NO subject alt name extension..."
   openssl req -new -key $data_dir/$certs_dir/$cert_cn.key -out $data_dir/$certs_dir/$cert_cn.csr -subj "$ca_dn_prefix/CN=$cert_cn" -passin pass:$ca_password 
else
   echo "creating cert with subject alt name extension..."
   openssl req -new -key $data_dir/$certs_dir/$cert_cn.key -out $data_dir/$certs_dir/$cert_cn.csr -subj "$ca_dn_prefix/CN=$cert_cn" -passin pass:$ca_password -addext "subjectAltName = $cert_subject_alt_name"
fi
   
openssl x509 -req -in $data_dir/$certs_dir/$cert_cn.csr -CA $data_dir/$ca_issuing_dir/ca.issuing.pem -CAkey $data_dir/$ca_issuing_dir/ca.issuing.key -out $data_dir/$certs_dir/$cert_cn.pem -days 3 -sha512 -copy_extensions copyall -passin pass:$ca_password

openssl rsa -in $data_dir/$certs_dir/$cert_cn.key -out $data_dir/$certs_dir/$cert_cn.key.decrypted -passin pass:$ca_password

