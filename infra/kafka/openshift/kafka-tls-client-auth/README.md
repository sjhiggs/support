# Simple TLS client authentication

Example of a basic config with TLS authentication and authorization to a topic. Meets the following requirements:

* operator managed certificates
* Route type listener
* TLS authentication for external clients
* Simple authorization, user alice has access to produce/consume from topic 'metamorphosis' and consume group 'metamorphosis-group'

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
oc create -n west -f config/west/topic-metamorphosis.yaml
oc create -n west -f config/west/user-alice.yaml
```

## extract user TLS certs

Create a local client config with the required client cert and trusted ca cert.  The client cert is created by the user operator and stored in a secret.

```
oc get -n west secret/alice -o jsonpath="{.data['user\.p12']}" | base64 -d > /tmp/alice.p12
export KEYSTORE_PASSWORD=`oc get -n west secret/alice -o jsonpath="{.data['user\.password']}" | base64 -d`
oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.p12']}"  | base64 -d > /tmp/truststore.p12
export TRUSTSTORE_PASSWORD=`oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.password']}" | base64 -d`
cat << EOF > /tmp/alice.properties
security.protocol=SSL
ssl.truststore.location=/tmp/truststore.p12
ssl.truststore.password=$TRUSTSTORE_PASSWORD
ssl.keystore.location=/tmp/alice.p12
ssl.keystore.password=$KEYSTORE_PASSWORD
ssl.endpoint.identification.algorithm=https
EOF
```


# Test client (requires Kafka binaries on local machine)

Use the local client configuration and test producing and consuming from topic.

```
export BOOTSTRAP_SERVER=`oc get -n west route/west-kafka-tls-bootstrap -o jsonpath="{.spec.host}"`
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --producer.config /tmp/alice.properties --topic metamorphosis

$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --consumer.config /tmp/alice.properties --topic metamorphosis --group metamorphosis-group --from-beginning
```



`
