# Simple MM2 configuration from west to east
```
oc new-project west
oc create -n west -f west/kafka-west.yaml
oc create -n west -f west/kafka-topic-west.yaml
oc new-project east
oc create -n east -f east/kafka-east.yaml
```

```
oc extract secret/west-cluster-ca-cert --to=/tmp/west-cluster-ca-cert --confirm -n west
oc  create secret generic -n east --from-file /tmp/west-cluster-ca-cert/ca.crt  west-cluster-ca-cert 
```

```
oc create -n east -f east/mm2.yaml
```

`
