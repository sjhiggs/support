# Single Kafka/Zookeeper on localhsot

```
export KAFKA_VERSION=3.9.1
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_server_jaas.conf"
cp config/single-sasl-plain/kafka_server_jaas.conf /tmp
```

```
/tmp/kafka-$KAFKA_VERSION/bin/zookeeper-server-start.sh  /tmp/kafka-$KAFKA_VERSION/config/zookeeper.properties
```

```
/tmp/kafka-$KAFKA_VERSION/bin/kafka-server-start.sh  ./config/single-sasl-plain/server.properties
```

## Allow alice to access foo topic
```
/tmp/kafka-$KAFKA_VERSION/bin/kafka-acls.sh --bootstrap-server localhost:9092 --add --allow-principal User:alice --operation Read --operation Write --topic foo --command-config config/single-sasl-plain/admin.properties
```

## Test alice produce to foo topic
```
/tmp/kafka-$KAFKA_VERSION/bin/kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic foo --producer.config=./config/single-sasl-plain/client.properties
```

## Remove access to foo topic for alice
```
/tmp/kafka-$KAFKA_VERSION/bin/kafka-acls.sh --bootstrap-server localhost:9092 --remove --allow-principal User:alice --operation Read --operation Write --topic foo --command-config config/single-sasl-plain/admin.properties
```

