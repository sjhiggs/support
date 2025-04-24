#!/bin/bash

cd "$(dirname "$0")"

source ./env

openssl genpkey -algorithm rsa -out $data_dir/$ca_issuing_dir/ca.issuing.key -AES-256-CBC -pkeyopt rsa_keygen_bits:$ca_key_bits -pass pass:$ca_password
openssl req -new -key $data_dir/$ca_issuing_dir/ca.issuing.key -out $data_dir/$ca_issuing_dir/ca.issuing.csr -addext "basicConstraints=critical,CA:TRUE" -subj "$ca_issuing_subject" -passin pass:$ca_password
openssl x509 -req -in $data_dir/$ca_issuing_dir/ca.issuing.csr -CA $data_dir/$ca_dir/ca.pem -CAkey $data_dir/$ca_dir/ca.key -out $data_dir/$ca_issuing_dir/ca.issuing.pem -days 365 -sha512 -CAcreateserial  -copy_extensions copyall -passin pass:$ca_password


