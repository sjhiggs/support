# Single Kafka/Zookeeper on localhsot

```

cp config/single-sasl-plain/kafka_server_jaas.conf /tmp
/tmp/kafka-3.9.0/bin/zookeeper-server-start.sh  /tmp/kafka-3.9.0/config/zookeeper.properties
/tmp/kafka-3.9.0/bin/kafka-server-start.sh  ./config/single-sasl-plain/server.properties
```

## Allow alice to access foo topic
```
/tmp/kafka-3.9.0/bin/kafka-acls.sh --bootstrap-server localhost:9092 --add --allow-principal User:alice --operation Read --operation Write --topic foo --command-config config/single-sasl-plain/admin.properties
```

## Test alice produce to foo topic
```
/tmp/kafka-3.9.0/bin/kafka-console-producer.sh --bootstrap-server 127.0.0.1:9092 --topic foo --producer.config=./config/single-sasl-plain/client.properties
```

## Remove access to foo topic for alice
```
/tmp/kafka-3.9.0/bin/kafka-acls.sh --bootstrap-server localhost:9092 --remove --allow-principal User:alice --operation Read --operation Write --topic foo --command-config config/single-sasl-plain/admin.properties
```

