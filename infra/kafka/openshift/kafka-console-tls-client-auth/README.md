# Kafka Console with Client Certificate Auth to Kafka

## Prerequisites

This project assumes you installed a Kafka cluster with TLS client authentication -- see project `../kafka-tls-client-auth` for installation instructions.

## Install console operator

```
oc create -f yaml/subscription.yaml
```

## Create a KafkaUser, used by the kafka console application to authenticate to the broker

```
oc create -f yaml/kafkauser-console.yaml
```

## Extract the kafka console user's certs/keys and create the secret needed by the console

```
oc get -n west secret/console-kafka-user -o jsonpath="{.data['user\.p12']}" | base64 -d > /tmp/console-kafka-user.p12
export KEYSTORE_PASSWORD=`oc get -n west secret/console-kafka-user -o jsonpath="{.data['user\.password']}" | base64 -d`
oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.p12']}"  | base64 -d > /tmp/truststore.p12
export TRUSTSTORE_PASSWORD=`oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.password']}" | base64 -d`
openssl pkcs12 -in /tmp/console-kafka-user.p12 -nocerts -nodes -passin env:KEYSTORE_PASSWORD | openssl rsa > /tmp/console-kafka-user.pem
openssl pkcs12 -in /tmp/console-kafka-user.p12 -clcerts -nokeys  -passin env:KEYSTORE_PASSWORD | awk '/BEGIN CERT/,/END CERT/' > /tmp/console-kafka-user-certs.pem
openssl pkcs12 -in /tmp/truststore.p12 -cacerts -nokeys  -passin env:TRUSTSTORE_PASSWORD | awk '/BEGIN CERT/,/END CERT/' > /tmp/truststore.pem
```

```
oc create secret generic console-kafka-west-auth --from-file=ssl.truststore.certificates=/tmp/truststore.pem --from-literal=ssl.truststore.type=PEM --from-file ssl.keystore.key=/tmp/console-kafka-user.pem --from-file=ssl.keystore.certificate.chain=/tmp/console-kafka-user-certs.pem --from-literal ssl.keystore.type=PEM --from-literal security.protocol=SSL
```

## Create the console

```
oc create -f yaml/console.yaml
```

