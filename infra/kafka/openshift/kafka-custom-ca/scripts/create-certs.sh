#!/bin/bash

rm -r /tmp/kafka-ca
mkdir /tmp/kafka-ca

echo "writing to /tmp/kafka-ca/ca.key, /tmp/kafka-ca/ca.crt, and /tmp/kafka-ca/ca.p12..."
openssl req -nodes -x509 -newkey rsa:2048 -keyout /tmp/kafka-ca/ca.key -out /tmp/kafka-ca/ca.crt -subj "/C=US/ST=North Carolina/L=Raleigh/O=Red Hat/OU=Support/CN=TEST CA"

openssl pkcs12 -export -in /tmp/kafka-ca/ca.crt -nokeys -out /tmp/kafka-ca/ca.p12 -password pass:foobar -caname /tmp/kafka-ca/ca.crt

