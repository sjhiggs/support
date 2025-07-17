# Example Manual Creation of Skupper Link

## Description

Manually create certificate and link between two sites.  This supports the following requirement:

* Link two sites without using a Skupper AcessToken.  The AccessToken must be populated with a url generated on the source site's AccessGrant.  The generated url includes a UUID, which makes it difficult to use by continuous delivery systems.

This example links a source site ("north") with a target site ("south").

## Create sites and demo app

Install operator if not done already.

```
oc create =f yaml/subscription.yaml
```

Create north/south sites -- frontend app is on the north site and backend app is on the south site

```
oc new-project north
oc new-project south
oc create -f yaml/north.yaml
oc create -f yaml/south.yaml
```

## Create Certificate resource on source site

Creates a new certificate request, and then a secret with the same name (mysite-certificate) is generated:

```
oc create -f yaml/mysite-certificate.yaml
```

## Copy generated secret to the target namespace

Use some yq to remove unwanted metatdata and create secret in the target namespace

```
oc get -n north secret/mysite-certificate  -o yaml |  yq 'del(.metadata.annotations, .metadata.creationTimestamp, .metadata.namespace, .metadata.ownerReferences, .metadata.resourceVersion, .metadata.uid)' | oc create -n south -f-
```

## Create link on target site

```
oc get -n north -o yaml Site/north | yq .status.endpoints | yq '.spec.endpoints += load("/dev/stdin")' yaml/link.yaml | oc create -f-
```


## Test

```
oc expose -n north deployment/frontend
oc expose -n north service/frontend
```

//open in a browser
```
oc get -n north route/frontend -o yaml | yq .spec.host
```

