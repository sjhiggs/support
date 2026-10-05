# MQTT Queue Cleanup Reproducer

Simple MQTT v5 reproducer to test queue/address cleanup behavior on AMQ 7.x brokers.

## What It Does

Creates an MQTT client that:
1. Connects to the broker
2. Subscribes to a topic (creates queue/address on broker)
3. Waits for a delay (time to inspect broker)
4. Disconnects **without** calling `unsubscribe()`

## MQTT Configuration

- `automaticReconnect = true`
- `connectionTimeout = 30`
- `keepAliveInterval = 30`
- `sessionExpiryInterval = 0` (session ends with connection)
- `cleanStart = true` (start fresh)
- `qos = 1`

## Building

```bash
mvn clean compile
```

## Running

```bash
mvn exec:java -Dbroker.url=tcp://localhost:1883
```

### Configuration Options

| Property | Default | Description |
|----------|---------|-------------|
| `broker.url` | `tcp://localhost:1883` | MQTT broker URL |
| `topic` | `test/queue/#` | Topic to subscribe to |
| `qos` | `1` | Quality of Service level |
| `client.count` | `1` | Number of clients to create |
| `delay.seconds` | `30` | Seconds to wait before disconnect |

### Example

```bash
mvn exec:java \
  -Dbroker.url=tcp://my-broker:1883 \
  -Dtopic=test/mqtt/# \
  -Ddelay.seconds=60
```

## Checking Broker

During the delay period, check your AMQ broker for queues/addresses:

**AMQ Console**: Navigate to Addresses/Queues and look for `mqtt-client-*`

**Artemis CLI**:
```bash
artemis queue stat --url tcp://localhost:61616
```

## Expected Behavior

With the current configuration (`cleanStart=true`, `sessionExpiryInterval=0`), the queue/address should be removed immediately when the client disconnects, even without calling `unsubscribe()`.
