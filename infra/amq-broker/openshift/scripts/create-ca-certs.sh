#!/bin/bash

cd "$(dirname "$0")"

ROUTE_URL=*.apps-crc.testing

echo "create a new CA, Issuing CA, server certificate, client certificate"
../../../ca/scripts/create.sh
../../../ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="DNS:127.0.0.1,DNS:localhost,DNS:$ROUTE_URL"
../../../ca/scripts/cert-client.sh --cn=myuser

echo "create truststore for both server and client, contains the CA certificate only..."
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar

echo "create server PKCS12 keystore with server cert, server key, and Issuing CA cert..."
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar

echo "create client PKCS12 keystore for client authentication..."
cat /tmp/ca-data/certs/myuser.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myuser.combined.pem
openssl pkcs12 -export -in /tmp/ca-data/certs/myuser.combined.pem -inkey /tmp/ca-data/certs/myuser.key -out /tmp/ca-data/certs/myuser.p12 -passin pass:foobar -passout pass:foobar


chmod -R a+r /tmp/ca-data


echo "create secret in Openshift for the server to use..."
oc create secret generic mysecret --from-file=broker.ks=/tmp/ca-data/certs/myserver.p12 --from-file=client.ts=/tmp/ca-data/certs/truststore.p12 --from-literal=keyStorePassword=foobar --from-literal=trustStorePassword=foobar


echo "done."
