# Kafka + Kroxylicious + HAProxy (Podman)

A 3-tier Kafka architecture running in Podman containers:

```
Client → HAProxy → Kroxylicious → Kafka (3-node cluster)
```

## Quick Start

```bash
# Start everything
./scripts/podman-start.sh

# Test it
./scripts/podman-test.sh

# Stop everything
./scripts/podman-stop.sh
```

## Manual Commands

```bash
# Start services
podman-compose up -d

# Check status
podman-compose ps

# View logs
podman-compose logs -f

# Stop services
podman-compose down
```

## Client Connection

```properties
bootstrap.servers=proxy.local:9095
```

**Note:** Requires `127.0.0.1 proxy.local` in `/etc/hosts`

## Ports

- **9095** - Kafka bootstrap
- **9096** - Kafka broker 0
- **9097** - Kafka broker 1  
- **9098** - Kafka broker 2
- **8404** - HAProxy stats (http://localhost:8404/stats)

## Usage Examples

```bash
export KAFKA_DIR=/tmp/kafka-4.3.1

# Create topic
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server proxy.local:9095 \
    --create --topic my-topic --partitions 3 --replication-factor 3

# Produce
echo "test message" | $KAFKA_DIR/bin/kafka-console-producer.sh \
    --bootstrap-server proxy.local:9095 --topic my-topic

# Consume
$KAFKA_DIR/bin/kafka-console-consumer.sh \
    --bootstrap-server proxy.local:9095 --topic my-topic --from-beginning
```

## Architecture

The setup includes:
- **3 Kafka nodes** (KRaft mode - no ZooKeeper)
- **Kroxylicious proxy** (Kafka protocol proxy)
- **HAProxy** (TCP load balancer)

All running in Podman containers with no port conflicts.

## Files

```
kraft-kroxylicious/
├── compose.yml                    # Podman/Docker Compose file
├── config/
│   ├── kafka/                     # Kafka configs (3 nodes)
│   ├── kroxylicious/              # Kroxylicious proxy config
│   └── haproxy/                   # HAProxy load balancer config
└── scripts/
    ├── podman-start.sh           # Start services
    ├── podman-test.sh            # Test cluster
    └── podman-stop.sh            # Stop services
```

## Requirements

- Podman and podman-compose
- Kafka client tools (for testing)

## Notes

- All services run in containers with isolated networks
- HAProxy forwards all traffic to Kroxylicious
- Kroxylicious proxies to the Kafka cluster
- No port conflicts due to container isolation
