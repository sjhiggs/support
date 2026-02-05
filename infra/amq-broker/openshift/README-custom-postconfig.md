
# Create a secret with the post-config script

```
 oc create -f yaml/broker/broker-postconfig.yaml
```

This secret is mounted via a template in the following ActiveMQArtemis CR

```
oc create -f yaml/broker/broker-postconfig.yaml
```

And automatically run by the init container's script.  The init container copies all the configs to ${CONFIG_INSTANCE_DIR}, so you can modify the files there before the broker copies them to the instance directory on broker start, for example to modify jgroups config:

```
     sed -i -e "s/\${APPLICATION_NAME}-\${PING_SVC_NAME}/${PING_SVC_NAME}/" ${CONFIG_INSTANCE_DIR}/etc/jgroups-ping.xml
```

