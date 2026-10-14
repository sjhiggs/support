# Kafka KRaft Multi-DC Disaster Recovery Simulation

## Overview

This scenario simulates a disaster recovery procedure for a Kafka cluster where the controller quorum is lost.

**Initial Setup:**
- Datacenter A: 2 controllers
- Datacenter B: 3 controllers

The disaster is simulated using separate KafkaNodePools, one for each datacenter.

## Procedure

### 1. Create the Cluster

```bash
oc create -f config
```

### 2. Verify PVC Retention Policy

Check that PVCs are configured to be retained (not deleted) with the `strimzi.io/delete-claim=false` annotation (this is the default):

```bash
oc get pvc -o custom-columns='NAME:.metadata.name,DELETE_CLAIM:.metadata.annotations.strimzi\.io/delete-claim'
```

### 3. Simulate Disaster - Remove 3 Controllers (Loss of Quorum)

Delete the Datacenter B controller nodepool, which removes 3 controllers and causes loss of quorum:

```bash
oc delete knp/controller-dc-b
```

**Note:** The cluster will lose quorum and become unavailable at this point.

### 4. Restore Quorum - Add New Controllers

Replace the 2-controller Datacenter A nodepool with a 3-controller configuration:

```bash
oc delete -f config/nodepool-controller-dc-a.yaml
oc create -f config-disaster/nodepool-controller-dc-a.yaml
```

**Note:** A restart of the Strimzi operator may be required at this point.

### 5. Restart Brokers (If Necessary)

If the brokers don't reconnect automatically, restart them:

```bash
oc delete pod multidc-broker-0 multidc-broker-1 multidc-broker-2
``` 





