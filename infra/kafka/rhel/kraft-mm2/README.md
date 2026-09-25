# Kafka MirrorMaker 2 (MM2) - KRaft Mode

Simple MirrorMaker 2 setup for replicating topics and consumer groups between two Kafka clusters.

## Overview

- Replicates topics from Cluster A → Cluster B
- Syncs consumer group offsets for failover
- KRaft mode (no ZooKeeper required)

## Quick Start

### 1. Start Everything

```bash
podman-compose up -d
```

Wait ~60 seconds for brokers to become healthy.

### 2. Deploy MM2 Connectors

```bash
# Topic replication
curl -X POST -H "Content-Type: application/json" \
  --data @config/connectors/a-to-b/source-connector.json \
  http://localhost:8083/connectors

# Consumer group sync  
curl -X POST -H "Content-Type: application/json" \
  --data @config/connectors/a-to-b/checkpoint-connector.json \
  http://localhost:8083/connectors
```

### 3. Verify

```bash
curl -s http://localhost:8083/connectors/mm2-source-a-to-b/status | jq .connector.state
# Expected: "RUNNING"
```

## Test: Topic Replication

### Create and Produce

```bash
# Create topic on source
podman exec kafka-a-0 /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka-a-0:9092 \
  --create --topic test-topic \
  --partitions 9 --replication-factor 3

# Produce messages
for i in {1..10}; do echo "message-$i"; done | \
  podman exec -i kafka-a-0 /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server kafka-a-0:9092 \
    --topic test-topic
```

### Wait and Verify on Target

```bash
# Wait for MM2 to discover topic (10 seconds)

# Consume from target cluster
podman exec kafka-b-0 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka-b-0:9092 \
  --topic test-topic \
  --from-beginning \
  --max-messages 10
```

## Test: Consumer Group Replication

### Create Consumer Group on Source

```bash
# Start consuming (creates group "test-group")
podman exec  kafka-a-0 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka-a-0:9092 \
  --topic test-topic \
  --group test-group \
  --from-beginning

# Let it consume some messages
sleep 5
```

### Verify Group on Target

```bash
# Wait for checkpoint sync (60 seconds)
sleep 65

# Check group exists on target
podman exec kafka-b-0 /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka-b-0:9092 \
  --describe --group test-group
```

## Configuration

- **Topic discovery**: Every 10 seconds
- **Consumer group sync**: Every 60 seconds  
- **Replication factor**: 3
- **Parallel tasks**: 3
- **Worker config**: `config/connect-distributed.properties` (7 minimal settings)

Config files:
- `config/connect-distributed.properties` - Worker configuration
- `config/connectors/a-to-b/` - Cluster A → B (normal operations)
- `config/connectors/b-to-a/` - Cluster B → A (failback)

**Critical setting** (in `config/connect-distributed.properties`):
```properties
bootstrap.servers=kafka-b-0:9092,kafka-b-1:9092,kafka-b-2:9092
```
Worker must connect to **target cluster** to prevent feedback loops.


## Cleanup

```bash
# Stop everything
podman-compose down

# Remove data (fresh start)
podman-compose down -v
```

