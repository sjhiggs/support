# AMQ Broker Shared-Store HA Cluster

3 live brokers + 1 backup broker with shared storage for high availability.

N.B. - created with use of AI - use at your own risk

## Architecture

```
Primary Cluster (3 brokers)
├── broker-ss-0 --> myvol-broker-ss-0 (RWX) <-- Shared with backup
├── broker-ss-1 --> myvol-broker-ss-1 (RWO)
└── broker-ss-2 --> myvol-broker-ss-2 (RWO)

Backup Broker
└── broker-cluster-follower-ss-0 --> myvol-broker-ss-0 (RWX) <-- Same storage as broker-ss-0
```

## Deployment

### 1. Create PVCs

```bash
oc apply -f yaml/custom-pvc-names.yaml
```

Wait for PVCs to bind:
```bash
oc get pvc
```

Expected: myvol-broker-ss-0 should be RWX, others RWO.

### 2. Deploy Primary Cluster

```bash
oc apply -f yaml/broker-cluster.yaml
```

Wait for all 3 brokers to be ready:
```bash
oc get pods -l ActiveMQArtemis=broker -w
```

### 3. Deploy Backup Broker

```bash
oc apply -f yaml/broker-cluster-follower.yaml
```

### 4. Verify

Check backup announcement:
```bash
oc logs broker-cluster-follower-ss-0 | grep "backup announced"
```

Note: Pod name uses the CR name "broker-cluster-follower" + "-ss-0" suffix.

Expected output:
```
AMQ221031: backup announced
```

Check all resources:
```bash
oc get activemqartemis,pods,pvc
```

## Configuration Details

### Primary Broker HA Policy

```yaml
brokerProperties:
  - "HAPolicyConfiguration=SHARED_STORE_PRIMARY"
  - "HAPolicyConfiguration.failbackDelay=0"                    # Immediate failback
  - "HAPolicyConfiguration.failoverOnServerShutdown=true"      # Signal backup on shutdown
  - "HAPolicyConfiguration.waitForActivation=true"             # Default 
```

### Backup Broker HA Policy

```yaml
brokerProperties:
  - "HAPolicyConfiguration=SHARED_STORE_BACKUP"
  - "HAPolicyConfiguration.allowFailBack=true"                 # Allow primary to reclaim role
  - "HAPolicyConfiguration.restartBackup=true"                 # Restart as backup after failback
```

### Cluster Discovery

Both primary and backup brokers use PING_SVC_NAME to discover each other:

```yaml
env:
  - name: PING_SVC_NAME
    value: broker-ping-svc
```

The operator automatically creates the `broker-ping-svc` service for cluster discovery.

### Shared Credentials

The backup broker reuses the primary broker's cluster credentials:

```yaml
env:
  - name: AMQ_CLUSTER_USER
    valueFrom:
      secretKeyRef:
        name: broker-credentials-secret
        key: AMQ_CLUSTER_USER
  - name: AMQ_CLUSTER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: broker-credentials-secret
        key: AMQ_CLUSTER_PASSWORD
```

### Shared Storage

Both broker-ss-0 and the backup mount the same PVC:

```yaml
extraVolumes:
  - name: broker-data
    persistentVolumeClaim:
      claimName: myvol-broker-ss-0  # Same as broker-ss-0
```

## Files

```
yaml/
├── custom-pvc-names.yaml         # Pre-created PVCs (myvol-broker-ss-0 is RWX)
├── broker-cluster.yaml           # 3-broker primary cluster  
└── broker-cluster-follower.yaml  # Backup broker sharing storage with broker-ss-0

scripts/
├── test-failover.sh               # Test failover (backup activation)
├── test-failback.sh               # Test failback (primary reclaims role)
└── cleanup.sh                     # Cleanup and restore environment
```

## Testing Failover

Automated test scripts are provided in the `scripts/` directory to verify HA functionality:

### Test Failover (Backup Activation)

```bash
# Run with defaults (namespace: myproject, timeout: 90s)
cd scripts
./test-failover.sh

# Run with custom namespace
./test-failover.sh my-namespace

# Run with custom namespace and timeout
./test-failover.sh my-namespace 120
```

**What it does:**
1. Scales down the operator to prevent auto-reconciliation
2. Deletes the StatefulSet (keeps pods running)
3. Deletes broker-ss-0 pod
4. Creates a mock broker-ss-0 pod (maintains DNS, no broker process)
5. Monitors backup for activation to LIVE status
6. Optionally keeps environment for failback test

**Expected result:**
- Backup detects primary shutdown
- Backup activates to LIVE in ~1 second
- Message: `AMQ221010: Backup Server is now active`
- Backup accepts connections on port 61616

### Test Failback (Primary Reclaims Role)

Run after `test-failover.sh` to test that the primary can reclaim its role:

```bash
# Run with defaults
./test-failback.sh

# Run with custom namespace and timeout
./test-failback.sh my-namespace 120
```

**Prerequisites:**
- Backup must be LIVE (from running `test-failover.sh` first)
- Choose to keep environment when prompted by failover test

**What it does:**
1. Verifies backup is currently LIVE
2. Removes mock broker-ss-0 pod
3. Scales operator back up
4. Monitors for primary to reclaim its role
5. Monitors for backup to return to standby

**Expected result:**
- Primary starts and requests file lock
- Backup detects primary return
- Backup relinquishes lock (failbackDelay=0)
- Primary becomes LIVE
- Backup returns to standby (0/1 Ready)

### Cleanup Only

To manually clean up after testing without running failback:

```bash
./cleanup.sh [namespace]
```

**Note:** The tests use a mock pod because Kubernetes auto-recovery is too fast
(~20-30 seconds) to observe failover in normal pod deletion scenarios.
