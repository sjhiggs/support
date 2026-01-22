# Simple SCRAM-SHA-512 client authentication

Example of a basic config with SCRAM-SHA-512 authentication and authorization to a topic. Meets the following requirements:

* operator managed certificates
* Route type listener
* SCRAM-SHA-512 authentication for external clients
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

## extract TLS truststore certs and SCRAM-SHA-512 credentials

Create a local client config with the required trusted ca cert and SCRAM-SHA-512 credentails.  The client credentials are created by the user operator and stored in a secret.

```
oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.p12']}"  | base64 -d > /tmp/truststore.p12
export TRUSTSTORE_PASSWORD=`oc get -n west secret/west-cluster-ca-cert -o jsonpath="{.data['ca\.password']}" | base64 -d`
export SCRAM=`oc get secret/alice -o yaml | yq '.data."sasl.jaas.config"' | base64 -d`

cat << EOF > /tmp/alice.properties
security.protocol=SASL_SSL
ssl.truststore.location=/tmp/truststore.p12
ssl.truststore.password=$TRUSTSTORE_PASSWORD
ssl.endpoint.identification.algorithm=https
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=$SCRAM
EOF
```


## Test client (requires Kafka binaries on local machine)

Use the local client configuration and test producing and consuming from topic.

```
export BOOTSTRAP_SERVER=`oc get -n west route/west-kafka-scramsha512-bootstrap -o jsonpath="{.spec.host}"`
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --producer.config /tmp/alice.properties --topic metamorphosis

$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP_SERVER:443  --consumer.config /tmp/alice.properties --topic metamorphosis --group metamorphosis-group --from-beginning
```



`
