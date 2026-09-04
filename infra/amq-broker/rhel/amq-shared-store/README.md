# AMQ Broker Shared-Store HA Configuration

This scenario demonstrates ActiveMQ Artemis configured for High Availability using the **Shared-Store** strategy with `failoverOnShutdown=true`.

**Default Version:** Apache ActiveMQ Artemis 2.56.0 (latest stable release)

## Overview

In a shared-store HA configuration:
- **Master** and **Backup** brokers share the same persistent storage (journal, bindings, paging, large messages)
- Only one broker is active at a time (active-passive setup)
- When the master shuts down or fails, the backup detects this and activates
- With `failoverOnShutdown=true`, a graceful shutdown of the master triggers immediate failover to the backup
- The backup acquires an exclusive lock on the shared journal to prevent split-brain scenarios

## Architecture

```
┌─────────────────┐        ┌─────────────────┐
│  Master Broker  │        │  Backup Broker  │
│   (port 61616)  │        │   (port 61617)  │
└────────┬────────┘        └────────┬────────┘
         │                          │
         │    Shared Storage Lock   │
         └──────────┬───────────────┘
                    │
            ┌───────▼────────┐
            │  Shared Store  │
            │  /tmp/shared-  │
            │     data/      │
            │  - journal     │
            │  - bindings    │
            │  - paging      │
            │  - large-msgs  │
            └────────────────┘
```

## Key Configuration

### Master (broker.xml)
```xml
<ha-policy>
   <shared-store>
      <master>
         <failover-on-shutdown>true</failover-on-shutdown>
      </master>
   </shared-store>
</ha-policy>
```

### Backup (broker-backup.xml)
```xml
<ha-policy>
   <shared-store>
      <slave>
         <failover-on-shutdown>true</failover-on-shutdown>
         <allow-failback>true</allow-failback>
      </slave>
   </shared-store>
</ha-policy>
```

### Shared Directories
Both brokers use the same storage paths:
- `/tmp/shared-data/journal`
- `/tmp/shared-data/bindings`
- `/tmp/shared-data/paging`
- `/tmp/shared-data/large-messages`

**Note:** In production, this would be on a network-attached storage (NFS, SAN, etc.)

## Install

### 1. Create Shared Storage Directory
```bash
mkdir -p /tmp/shared-data/{journal,bindings,paging,large-messages}
```

### 2. Install Master Instance

Using the automated setup script (recommended):
```bash
./scripts/setup-ha.sh
# Or specify a different version:
# ./scripts/setup-ha.sh 2.55.0
```

Or manually:
```bash
../scripts/install.sh
```

### 3. Install Backup Instance
Create a separate backup instance:
```bash
# Create backup instance
/tmp/artemis_setup/apache-artemis-*/bin/artemis create /tmp/amq-shared-store-backup-instance \
    --user admin \
    --password admin \
    --allow-anonymous \
    --silent

# Copy backup configuration
cp etc/broker-backup.xml /tmp/amq-shared-store-backup-instance/etc/broker.xml
cp etc/bootstrap-backup.xml /tmp/amq-shared-store-backup-instance/etc/bootstrap.xml
cp etc/login.config /tmp/amq-shared-store-backup-instance/etc/
cp etc/artemis-users.properties /tmp/amq-shared-store-backup-instance/etc/
cp etc/artemis-roles.properties /tmp/amq-shared-store-backup-instance/etc/
```

## Run

### Start Master Broker
```bash
/tmp/amq-shared-store-instance/bin/artemis run
```

You should see log messages indicating the master is active:
```
INFO  [org.apache.activemq.artemis.core.server] AMQ221007: Server is now live
```

### Start Backup Broker (in a separate terminal)
```bash
/tmp/amq-shared-store-backup-instance/bin/artemis run
```

You should see the backup waiting:
```
INFO  [org.apache.activemq.artemis.core.server] AMQ221031: backup announced
```

## Test Failover

### 1. Connect a Client to Master
```bash
/tmp/amq-shared-store-instance/bin/artemis producer \
    --user admin \
    --password admin \
    --url "tcp://localhost:61616" \
    --destination test.queue \
    --message-count 10
```

### 2. Gracefully Stop Master
In the master terminal, press `Ctrl+C` or:
```bash
/tmp/amq-shared-store-instance/bin/artemis stop
```

With `failoverOnShutdown=true`, the backup should immediately activate:
```
INFO  [org.apache.activemq.artemis.core.server] AMQ221007: Server is now live
INFO  [org.apache.activemq.artemis.core.server] AMQ221020: Started EPOLL Acceptor at 0.0.0.0:61617
```

### 3. Consume Messages from Backup
```bash
/tmp/amq-shared-store-backup-instance/bin/artemis consumer \
    --user admin \
    --password admin \
    --url "tcp://localhost:61617" \
    --destination test.queue \
    --message-count 10
```

The messages should be available since both brokers share the same persistent store.

## Failback

If `allow-failback=true` is set (as in this configuration), when you restart the original master:

1. The backup (now active) will detect the original master coming back
2. The backup will hand control back to the original master
3. The backup will return to standby mode

## Client Failover URL

Clients can use a failover URL to automatically reconnect to the backup:
```
failover:(tcp://localhost:61616,tcp://localhost:61617)
```

Example:
```bash
/tmp/amq-shared-store-instance/bin/artemis producer \
    --url "failover:(tcp://localhost:61616,tcp://localhost:61617)" \
    --destination test.queue \
    --message-count 100
```

## Monitoring

### Check Master Status
```bash
/tmp/amq-shared-store-instance/bin/artemis queue stat --user admin --password admin
```

### Check Backup Status
```bash
/tmp/amq-shared-store-backup-instance/bin/artemis queue stat --user admin --password admin
```

### Web Console
- Master: http://localhost:8161/console
- Backup: http://localhost:8162/console (only accessible when backup becomes active)

## Production Considerations

1. **Shared Storage:** Use enterprise-grade shared storage (NFS, SAN, cloud block storage)
2. **Network Configuration:** Ensure reliable, low-latency network between brokers
3. **Fencing:** Implement STONITH/fencing mechanisms to prevent split-brain
4. **Monitoring:** Monitor lock file acquisition and broker state transitions
5. **Backup Hardware:** Backup server should have similar capacity to master
6. **Testing:** Regularly test failover scenarios in non-production environments

## Differences from Replication HA

| Feature | Shared-Store HA | Replication HA |
|---------|----------------|----------------|
| Storage | Shared (NFS/SAN) | Independent per broker |
| Data Sync | Via shared filesystem | Network replication |
| Failover Speed | Fast (lock acquisition) | Depends on replication lag |
| Infrastructure | Requires shared storage | Just network connectivity |
| Split-brain Prevention | Filesystem locks | Quorum/network checks |

## Troubleshooting

### Backup Won't Start
- Check that shared storage is accessible
- Verify no lock files are held by crashed processes: `rm -f /tmp/shared-data/*.lock`

### Failover Not Happening
- Verify `failover-on-shutdown=true` is set in both configurations
- Check cluster connectivity (UDP multicast on 231.7.7.7:9876)
- Review logs for connection errors

### Messages Lost After Failover
- Ensure persistence is enabled
- Verify shared storage directories are correctly mounted
- Check journal sync settings (`journal-datasync=true`)
