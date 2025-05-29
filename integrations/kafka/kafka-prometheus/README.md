# Integrate AMQ Streams with Openshift monitoring

## Init

For local development/testing, configure openshift local environment to enable clustering monitoring stack, then start openshift local.

```
crc config set enable-cluster-monitoring true
```

Create new project, then create the AMQ Streams operator:

```
oc new-project myproject
oc create -f yaml/subscription
```

```
oc create -f yaml/cluster-monitoring-config.yaml
oc create -f yaml/user-workload-monitoring-config.yaml
```

```
oc get pods -n openshift-user-workload-monitoring
```

# Install AMQ Streams and metrics export config

```
oc project myproject
oc create -f yaml/kafka-metrics.yaml
oc create -f yaml/strimzi-pod-monitor.yaml
oc create -f yaml/kafka-topioc.yaml
```

# Query

In the openshift monitoring console, run an example query:

```
sum(irate(kafka_server_brokertopicmetrics_messagesin_total{namespace="myproject",topic="foo"}[1m]))
```
