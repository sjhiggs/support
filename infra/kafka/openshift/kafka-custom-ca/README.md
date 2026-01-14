# Simple TLS client authentication

Example of a basic config with TLS liatener using a custom CA. Meets the following requirements:

* user managed certificates
* Route type TLS listener

## Prerequisites

Create ca pkcs12:
```
./scripts/create-certs.sh
```

```
oc create secret generic  west-clients-ca-cert --from-file=ca.crt=/tmp/kafka-ca/ca.crt --from-file=ca.p12=/tmp/kafka-ca/ca.p12 --from-literal=ca.password=foobar
oc create secret generic  west-cluster-ca-cert --from-file=ca.crt=/tmp/kafka-ca/ca.crt --from-file=ca.p12=/tmp/kafka-ca/ca.p12 --from-literal=ca.password=foobar
```


## Install operator

```
oc create -f ../subscription.yaml 
```

## Create KafkaNodePools, Kafka broker, Kafka User, and Kafka Topic

Create a Kafka user with TLS authentication and access to produce/consume from Kafka topic.

```
oc new-project west
oc create -n west -f config/west/nodepool-broker.yaml 
oc create -n west -f config/west/nodepool-controller.yaml 
oc create -n west -f config/west/kafka.yaml
oc create -n west -f config/west/user-alice.yaml
oc create -n west -f config/west/topic-metamorphosis.yaml

```


## Test client (requires Kafka binaries on local machine)

Use the local client configuration and test producing and consuming from topic.

```
../../rhel/scripts/kafka-get.sh --kafka-version=3.9.1
export KAFKA_DIR=/tmp/kafka-3.9.1
export BOOTSTRAP_SERVER=`oc get -n west route/west-kafka-tls-bootstrap -o jsonpath="{.spec.host}"`
scripts/create-client-properties.sh
```

```
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --producer.config /tmp/kafka-ca/alice.properties --topic metamorphosis

$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --consumer.config /tmp/kafka-ca/alice.properties --topic metamorphosis --group metamorphosis-group --from-beginning
```



`
