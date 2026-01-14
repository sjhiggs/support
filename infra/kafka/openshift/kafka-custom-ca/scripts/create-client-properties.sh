#!/bin/bash

oc get -n west secret/alice -o jsonpath="{.data['user\.p12']}" | base64 -d > /tmp/kafka-ca/alice.p12
export KEYSTORE_PASSWORD=`oc get -n west secret/alice -o jsonpath="{.data['user\.password']}" | base64 -d`
oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.p12']}"  | base64 -d > /tmp/kafka-ca/truststore.p12
export TRUSTSTORE_PASSWORD=`oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.password']}" | base64 -d`

cat << EOF > /tmp/kafka-ca/alice.properties
security.protocol=SSL
ssl.truststore.location=/tmp/kafka-ca/truststore.p12
ssl.truststore.password=$TRUSTSTORE_PASSWORD
ssl.keystore.location=/tmp/kafka-ca/alice.p12
ssl.keystore.password=$KEYSTORE_PASSWORD
ssl.endpoint.identification.algorithm=https
EOF

