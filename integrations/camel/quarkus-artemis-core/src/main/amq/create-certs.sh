#!/bin/bash

../../../infra/ca/
../../../infra/ca/scripts/create.sh
../../../infra/ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="IP:127.0.0.1,DNS:localhost,DNS:mybroker"
../../../infra/ca/scripts/cert-client.sh --cn=myuser

cat /tmp/ca-data/certs/myuser.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myuser.combined.pem
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar
openssl pkcs12 -export -in /tmp/ca-data/certs/myuser.combined.pem -inkey /tmp/ca-data/certs/myuser.key -out /tmp/ca-data/certs/myuser.p12 -passin pass:foobar -passout pass:foobar
chmod -R a+r /tmp/ca-data

