# Install a KRaft cluster without authentication

## Init

```
export KAFKA_VERSION=4.3.1
../scripts/kafka-get.sh --kafka-version=$KAFKA_VERSION
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION
```

```
./scripts/init-kraft-noauth.sh
./scripts/start-cluster-kraft-noauth.sh
```

## Add quorum members

```
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090 --command-config config/kraft-noauth/controller-1.properties add-controller
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090 --command-config config/kraft-noauth/controller-2.properties add-controller
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090,127.0.0.1:10091,127.0.0.1:10092 describe --replication --human-readable
```

## Client Test

```
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090 --create --topic foo --partitions 3 --replication-factor 3
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --topic foo
```
```
$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --topic foo --group foo-consumer-group --from-beginning
```

## Shut down

```
./scripts/stop-cluster-kraft.sh
```
