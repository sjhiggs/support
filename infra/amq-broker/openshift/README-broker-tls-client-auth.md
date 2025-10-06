# Description

Example of a simple two-way TLS configuration with client test.

# Init

Create a new project an operator for AMQ broker:

```
oc new-project myproject
oc create -f yaml/subscription/subscription-7.13.x.yaml 
```

Use the following script to create the server and client certs and `mysecret` secret that the broker will use for TLS.  Note that this generates a root CA, intermediate/issuing CA, client cert and key, and server cert and key.  The server keystore contains the server cert, server key, and issuing CA cert.  The client keystore contains the client cert, client key, and issuing CA cert.  Both the client and server use the same root CA in a truststore.

ALso note that the script assumes a wildcard domain of `apps-crc.testing`, this may need to be adjusted for environments other than openshift local.

```
./scripts/create-ca-certs.sh
```

# Install broker

```
oc create -f yaml/broker/broker-ssl-acceptor.yaml 
```

# Tests

## Check client auth via openssl

```
echo "OK" | openssl s_client -CAfile /tmp/ca-data/ca/ca.pem -servername broker-ssl-acceptor-0-svc-rte-myproject.apps-crc.testing -connect broker-ssl-acceptor-0-svc-rte-myproject.apps-crc.testing:443  -cert /tmp/ca-data/certs/myuser.combined.pem -key /tmp/ca-data/certs/myuser.key
```

## Test AMQPS

```
bin/artemis producer --url "amqps://broker-ssl-acceptor-0-svc-rte-myproject.apps-crc.testing:443?transport.trustStoreLocation=/tmp/ca-data/certs/truststore.p12&transport.trustStorePassword=foobar&transport.keyStoreLocation=/tmp/ca-data/certs/myuser.p12&transport.keyStorePassword=foobar" --threads 1 --protocol amqp --message-count 10 --destination 'queue://foo'
```

## Test Core

```
./bin/artemis producer --url 'tcp://broker-ssl-acceptor-0-svc-rte-myproject.apps-crc.testing:443?sslEnabled=true&trustStorePath=/tmp/ca-data/certs/truststore.p12&trustStorePassword=foobar&keyStorePath=/tmp/ca-data/certs/myuser.p12&keyStorePassword=foobar&verifyHost=true&useTopologyForLoadBalancing=false' --user admin --password admin  --message-count 1 --destination queue://test.foo --message "Hello, World!" --verbose
```
