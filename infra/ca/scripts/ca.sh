#!/bin/bash

cd "$(dirname "$0")"
echo $PWD
source ./env

openssl genpkey -algorithm rsa -out $data_dir/$ca_dir/ca.key -AES-256-CBC -pkeyopt rsa_keygen_bits:"$ca_key_bits" -pass pass:$ca_password
openssl req -x509 -new -key $data_dir/$ca_dir/ca.key -days $ca_cert_expire_days -out $data_dir/$ca_dir/ca.pem -sha512 -subj "$ca_subject" -passin pass:$ca_password

