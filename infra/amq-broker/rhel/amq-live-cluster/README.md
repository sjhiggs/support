# AMQ Broker Live Cluster

Two-broker ActiveMQ Artemis cluster with static discovery.

## Architecture

```
┌──────────┐        ┌──────────┐
│ Broker1  │◄──────►│ Broker2  │
│ :61616   │ Cluster│ :61617   │
└──────────┘        └──────────┘
```

Both brokers are live with independent storage. Messages distribute on-demand across the cluster.

## Install

```bash
./scripts/setup-cluster.sh
```

Or specify version:
```bash
./scripts/setup-cluster.sh 2.55.0
```

## Run

Terminal 1:
```bash
/tmp/broker1-instance/bin/artemis run
```

Terminal 2:
```bash
/tmp/broker2-instance/bin/artemis run
```

## Test

Send to broker1:
```bash
/tmp/broker1-instance/bin/artemis producer \
    --url tcp://localhost:61616 \
    --destination test.queue \
    --message-count 10
```

Consume from broker2:
```bash
/tmp/broker2-instance/bin/artemis consumer \
    --url tcp://localhost:61617 \
    --destination test.queue \
    --message-count 10
```

Messages redistribute on-demand when consumers connect.

## Web Consoles

- Broker1: http://localhost:8161/console
- Broker2: http://localhost:8162/console
- Credentials: admin/admin

## Configuration

- **Clustering:** Static connectors
- **Load balancing:** ON_DEMAND
- **Storage:** Independent per broker
- **Ports:** 61616 (broker1), 61617 (broker2)
