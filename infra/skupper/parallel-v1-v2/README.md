# Example Skupper v1 and v2

This shows how to run skupper operators v1 and v2 in parallel on the same kubernetes/openshift cluster.

## install operators

```
oc new-project skupper-operator-v1
oc create -f yaml/subscription-skupper-operator-v1.yaml

oc new-project skupper-operator-v2
oc create -f yaml/operator-subscriptions/subscription-skupper-operator-v2.yaml
```

## v1 on the east/west namespaces

```
oc new-project west
oc new-project east

oc create -f yaml/west.yaml
oc create -f yaml/east.yaml
```

```
curl https://skupper.io/install.sh | sh
oc project west
skupper token create ~/secret.token
oc project east
skupper link create ~/secret.token
```

```
oc -n west expose deployment/frontend
oc -n west expose service/frontend
```


## v2 on the north/south namespaces

```
oc new-project north
oc new-project south

oc create -f yaml/north.yaml
oc create -f yaml/south.yaml
```

```
curl https://skupper.io/v2/install.sh | sh
oc project north
skupper token issue ~/secretv2.token
oc project south
skupper token redeem ~/secretv2.token
```

```
oc -n north expose deployment/frontend
oc -n north expose service/frontend
```


