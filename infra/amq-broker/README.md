# Run an AMQ broker in podman

## Initialize

Use the "ca" project to initialize a new CA, Issuing CA, and broker certs:

```
../ca/scripts/create.sh
../ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="DNS:127.0.0.1,DNS:localhost"
../ca/scripts/cert-client.sh --cn=myuser 
```

Create truststore, client auth pkcs12, server pkc12:

```
cat /tmp/ca-data/certs/myuser.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myuser.combined.pem
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar
openssl pkcs12 -export -in /tmp/ca-data/certs/myuser.combined.pem -inkey /tmp/ca-data/certs/myuser.key -out /tmp/ca-data/certs/myuser.p12 -passin pass:foobar -passout pass:foobar
chmod -R a+r /tmp/ca-data
```

## Run podman

### Plain/SSL with Dual Auth

Starts broker with plain and ssl acceptors, client cert authentication and plain auth:

```
$ cat podman/podman-compose-plain-ssl-dual-auth.yaml | podman-compose -f- up
```


## Check certs

```
$ echo "OK" | openssl s_client -CAfile /tmp/ca-data/ca/ca.pem -servername localhost -connect localhost:61617 -cert /tmp/ca-data/certs/myuser.combined.pem -key /tmp/ca-data/certs/myuser.key
```


## Run client

### plain authentication
camel run --source-dir=camel-amq-client --dep=camel-amqp --profile=plain

### ssl with plain authentication
camel run --source-dir=camel-amq-client --dep=camel-amqp --profile=ssl

### ssl with client auth
camel run --source-dir=camel-amq-client --dep=camel-amqp --profile=client-auth




