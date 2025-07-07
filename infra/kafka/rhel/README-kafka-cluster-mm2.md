# Run a Kafka Cluster(s) on localhost

## Startup

```
export KAFKA_DIR=/tmp/kafka-3.9.0
```

<<<<<<< Updated upstream
Start Cluster A and B (also, see scripts dir)
```
LOG_DIR=/tmp/zookeeper-0/logs $KAFKA_DIR/bin/zookeeper-server-start.sh -daemon ./config/cluster-a/zookeeper-0.properties
LOG_DIR=/tmp/kafka-0/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-a/server-0.properties
LOG_DIR=/tmp/kafka-1/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-a/server-1.properties
LOG_DIR=/tmp/kafka-2/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-a/server-2.properties

LOG_DIR=/tmp/zookeeper-1/logs $KAFKA_DIR/bin/zookeeper-server-start.sh -daemon ./config/cluster-b/zookeeper-1.properties
LOG_DIR=/tmp/kafka-3/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-b/server-3.properties
LOG_DIR=/tmp/kafka-4/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-b/server-4.properties
LOG_DIR=/tmp/kafka-5/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ./config/cluster-b/server-5.properties
```

## Shut Down, Clear Data
=======
Start Cluster west and est (also, see scripts dir)
>>>>>>> Stashed changes

```
```

# Simple Mirrormaker test

```
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server localhost:9090 --create --config min.insync.replicas=2 --replication-factor=3 --topic=foo
$KAFKA_DIR/bin/kafka-producer-perf-test.sh --producer-props bootstrap.servers=127.0.0.1:9090 --num-records 10 --topic foo --record-size 100 --throughput 100
$KAFKA_DIR/bin/kafka-consumer-perf-test.sh --bootstrap-server=127.0.0.1:9090 --topic foo --group foo-consumer-group --messages 10
LOG_DIR=/tmp/mm2-logs $KAFKA_DIR/bin/connect-mirror-maker.sh ./config/mm2-a-b.properties
```

```
$KAFKA_DIR/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9093 --describe --group foo-consumer-group
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server localhost:9093 --describe --topic foo
```

