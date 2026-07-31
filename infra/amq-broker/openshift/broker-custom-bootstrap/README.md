# Description

Simple broker with a custom `bootstrap.xml` mounted via a ConfigMap.  This example enables HTTP request logging by adding a `<request-log>` element to the web binding in `bootstrap.xml`.

Access logs are written to `${artemis.instance}/log/http-access-yyyy_MM_dd.log` inside the broker pod.

The custom `bootstrap.xml` is staged at `/amq/custom/` in the init container, and a post-config script copies it to `${CONFIG_INSTANCE_DIR}/etc/` so the path is resolved dynamically regardless of the CR name.

# Init

```
oc new-project myproject
oc create -f ../shared/yaml/subscription/subscription-7.13.x.yaml
```

# Create the ConfigMaps

```
oc create -f yaml/artemis-bootstrap-config.yaml
oc create -f yaml/post-config.yaml
```

# Install broker

```
oc create -f yaml/broker.yaml
```

# Verify

Check that the custom bootstrap.xml is in place:

```
oc exec artemis-broker-ss-0 -- cat /home/jboss/amq-broker/etc/bootstrap.xml
```

Check that HTTP access logs are being written (hit the console first to generate a log entry):

```
oc exec artemis-broker-ss-0 -- ls /home/jboss/amq-broker/log/
```
