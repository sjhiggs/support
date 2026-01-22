# Kafka Console with SCRAM-SHA-512 Auth to Kafka

## Prerequisites

This project assumes you installed a Kafka cluster with SCRAM-SHA-512 client authentication -- see project `../kafka-scram-sha-client-auth` for installation instructions.

## Install console operator

```
oc create -f yaml/subscription.yaml
```

## Create a KafkaUser, used by the kafka console application to authenticate to the broker

```
oc create -f yaml/kafkauser-console.yaml
```

## Configure security protocol for the authentication to Kafka

```
oc create secret generic console-kafka-west-auth  --from-literal security.protocol=SASL_SSL
```


## Create the console

```
oc create -f yaml/console.yaml
```

## Authenticate to console

Use console-kafka-user password:

```
oc get secret/console-kafka-user  -o yaml | yq .data.password | base64 -d
```

