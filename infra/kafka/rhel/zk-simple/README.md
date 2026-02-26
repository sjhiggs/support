# Run a Kafka Cluster(s) on localhost

Scripts created by AI - use at your own risk!

Startup
```
export KAFKA_DIR=/tmp/kafka-3.9.1
./scripts/start-all.sh
```

Test
```
./scripts/test-cluster.sh
./scripts/test-failover.sh
./scripts/cluster-status.sh
```

Shutdown
```
./scripts/clean.sh
```


