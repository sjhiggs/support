# AMQ Broker Shared-Store HA Test Scripts

This directory contains automated test scripts for verifying shared-store HA failover and failback behavior.

## Scripts

### `test-failover.sh` - Test Backup Activation

Tests that the backup broker activates to LIVE when the primary fails.

**Usage:**
```bash
./test-failover.sh [NAMESPACE] [TIMEOUT]
```

**Environment Variables:**
- `NAMESPACE` - OpenShift namespace (default: `myproject`)
- `TIMEOUT` - Monitoring timeout in seconds (default: `90`)

**Examples:**
```bash
# Run with defaults
./test-failover.sh

# Custom namespace
./test-failover.sh production

# Custom namespace and timeout
./test-failover.sh production 120

# Using environment variables
NAMESPACE=test TIMEOUT=60 ./test-failover.sh
```

**What it does:**
1. Scales down the AMQ Broker operator
2. Deletes the StatefulSet (keeps pods running)
3. Deletes `broker-ss-0` pod
4. Creates a mock `broker-ss-0` (sleep pod, maintains DNS)
5. Monitors `broker-cluster-follower-ss-0` for activation
6. Optionally preserves environment for failback test

**Expected output:**
```
✅ BACKUP ACTIVATED TO LIVE!

Activation timeline:
2026-09-01 17:01:00,963 INFO  nodeID b2ef4733-a60c-11f1-bd02-0a580ad9004f is closing
2026-09-01 17:01:01,703 INFO  AMQ221010: Backup Server is now active
```

---

### `test-failback.sh` - Test Primary Reclaiming Role

Tests that the primary can reclaim its role when it returns.

**Prerequisites:**
- Backup must be LIVE (run `test-failover.sh` first)
- Keep environment when prompted by failover test

**Usage:**
```bash
./test-failback.sh [NAMESPACE] [TIMEOUT]
```

**Environment Variables:**
- `NAMESPACE` - OpenShift namespace (default: `myproject`)
- `TIMEOUT` - Monitoring timeout in seconds (default: `120`)

**Examples:**
```bash
# Run with defaults
./test-failback.sh

# Custom namespace
./test-failback.sh production

# Custom namespace and timeout  
./test-failback.sh production 180
```

**What it does:**
1. Verifies backup is currently LIVE
2. Removes mock `broker-ss-0` pod
3. Scales operator back to 1 replica
4. Monitors primary for activation
5. Monitors backup for return to standby

**Expected output:**
```
✅ FAILBACK COMPLETED!

Primary logs:
2026-09-01 17:07:42,426 INFO  AMQ221006: Waiting to obtain primary lock
2026-09-01 17:08:15,123 INFO  AMQ221007: Server is now active

Backup logs:
2026-09-01 17:08:15,200 INFO  AMQ221109: waiting for primary to fail before activating
```

---

### `cleanup.sh` - Cleanup and Restore

Cleans up test environment and restores normal operation.

**Usage:**
```bash
./cleanup.sh [NAMESPACE]
```

**Environment Variables:**
- `NAMESPACE` - OpenShift namespace (default: `myproject`)

**Examples:**
```bash
# Run with default namespace
./cleanup.sh

# Custom namespace
./cleanup.sh production
```

**What it does:**
1. Removes mock `broker-ss-0` pod if present
2. Scales operator back to 1 replica
3. Allows operator to reconcile the environment

**Note:** This runs automatically at the end of `test-failover.sh` and `test-failback.sh` unless you choose to keep the environment.

---

## Typical Test Workflow

### Complete HA Test (Failover + Failback)

```bash
# 1. Test failover
./test-failover.sh

# When prompted "Keep environment for failback test?", answer: y

# 2. Test failback
./test-failback.sh

# Environment is automatically cleaned up
```

### Failover Test Only

```bash
# Test failover
./test-failover.sh

# When prompted "Keep environment for failback test?", answer: n
# (automatic cleanup runs)
```

### Manual Cleanup

If you need to manually clean up at any time:

```bash
./cleanup.sh
```

---

## Why Mock Pods?

The tests use mock pods (sleep containers) to prevent Kubernetes auto-recovery, which is too fast (~20-30 seconds) to observe failover behavior. The mock pod:

- Maintains DNS resolution (pod has IP and hostname)
- Prevents StatefulSet from recreating the pod
- Allows backup enough time to detect primary is gone
- Enables observation of backup activation

Without this approach, Kubernetes restarts `broker-ss-0` before the backup can activate, making it impossible to test failover in a lab environment.

---

## Troubleshooting

### Failover test times out

**Cause:** Backup may not be detecting shutdown or timeout is too short

**Solutions:**
- Increase timeout: `./test-failover.sh myproject 180`
- Check backup logs: `oc logs broker-cluster-follower-ss-0`
- Verify configuration includes `failoverOnServerShutdown=true` on primary

### Failback test shows partial success

**Cause:** Failback may still be in progress

**Solutions:**
- Wait a bit longer and check pod status manually
- Verify `failbackDelay=0` in primary configuration
- Check that `allowFailBack=true` in backup configuration

### Primary logs show "becoming singleton" during failback

**Cause:** JGroups cluster discovery taking longer than expected

**What it means:**
- JGroups tried to discover cluster members via DNS/multicast
- After 10 attempts without finding members, it creates its own cluster view
- This may be transient - failback may still complete successfully

**What to check:**
- Wait longer - failback may take 1-2 minutes to complete
- Check if backup eventually returns to standby (0/1 Ready)
- Verify PING_SVC_NAME is configured correctly
- Check network connectivity between pods

**Note:** This warning doesn't necessarily mean failback failed - it may just indicate
a delay in cluster discovery. The file lock mechanism and failback should still work.

### Cleanup fails

**Cause:** Resources may have been manually modified

**Solutions:**
- Delete mock pod manually: `oc delete pod broker-ss-0 --force`
- Scale operator manually: `oc scale deployment amq-broker-controller-manager --replicas=1 -n openshift-operators`
- Wait for operator to reconcile

---

## Configuration Requirements

The tests expect the following HA configuration:

**Primary (broker-cluster.yaml):**
```yaml
HAPolicyConfiguration=SHARED_STORE_PRIMARY
HAPolicyConfiguration.failbackDelay=0
HAPolicyConfiguration.failoverOnServerShutdown=true
HAPolicyConfiguration.waitForActivation=false  # MUST be false for failback to work
```

**Note on `waitForActivation`:** This setting controls Java API behavior (whether `start()` 
blocks), not failback functionality. Default is `true`. Either value works for HA.

**Backup (broker-cluster-follower.yaml):**
```yaml
HAPolicyConfiguration=SHARED_STORE_BACKUP
HAPolicyConfiguration.allowFailBack=true
HAPolicyConfiguration.restartBackup=true
```

See parent README.md for complete deployment instructions.
