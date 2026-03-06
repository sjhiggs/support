#!/bin/bash

# 1. Convert the client certificate and private key
# (The -nodes flag prevents encrypting the output key so Python can read it without a password)
openssl pkcs12 -in /tmp/myapp-certs/myuser.p12 -out /tmp/myapp-certs/myuser.pem -nodes

# 2. Convert the truststore (extracting the CA certificate to verify the server)
openssl pkcs12 -in /tmp/myapp-certs/truststore.p12 -out /tmp/myapp-certs/truststore.pem -nokeys
