# Run a Kafka Cluster(s) on localhost

Scripts created by AI - use at your own risk!

Startup
```
export KAFKA_DIR=/tmp/kafka-3.9.2
./scripts/start-all.sh
```

Test
```
./scripts/test-cluster.sh
./scripts/test-failover.sh
./scripts/cluster-status.sh -g test-group
```

Shutdown
```
./scripts/clean.sh
```


