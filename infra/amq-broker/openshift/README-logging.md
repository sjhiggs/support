
# Step 1 - Create Secret

```
oc create secret generic newlog4j-logging-config --from-file=conf/logging.properties
```

# Step 2 - add secret to ActiveMQArtemis CR

```
spec:
  deploymentPlan:
    ...
    extraMounts:
      secrets:
      - "newlog4j-logging-config"

```

