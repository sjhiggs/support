# Install local podman IBM-MQ instance (Non-SSL)

## Details

* Queue manager QM1
* Queue DEV.QUEUE.1
* Channel: DEV.APP.SVRCONN
* Listener: SYSTEM.LISTENER.TCP.1 on port 1414
* Username: app
* Password: foobar


## Create podman container

```
podman pull icr.io/ibm-messaging/mq:latest
podman volume create qm1data
podman run --env LICENSE=accept --env MQ_QMGR_NAME=QM1 --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --env MQ_APP_PASSWORD=foobar --env MQ_ADMIN_PASSWORD=passw0rd --name QM1 icr.io/ibm-messaging/mq:latest
```

## Test local IBM MQ instance with camel route

Requires jbang with camel
Tested with Java 21 (uses jakarta package name). Run the route:

```
$  camel run camel-mq-client/MQRoute.java --profile=dev --dep=com.ibm.mq:com.ibm.mq.jakarta.client:9.4.2.0
```


# Install with SSL


## Initialize certificates

Use the "ca" project to initialize a new CA, Issuing CA, and broker certs:

```
../ca/scripts/create.sh
../ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="DNS:127.0.0.1,DNS:localhost"
../ca/scripts/cert-client.sh --cn=app
```

Configure PKC12 keystore/truststore for the client application

```
cat /tmp/ca-data/certs/app.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/app.combined.pem
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar
openssl pkcs12 -export -in /tmp/ca-data/certs/app.combined.pem -inkey /tmp/ca-data/certs/app.key -out /tmp/ca-data/certs/app.p12 -passin pass:foobar -passout pass:foobar
chmod -R a+r /tmp/ca-data
```

## Create podman container

```
podman pull icr.io/ibm-messaging/mq:latest
cat podman/podman-compose-plain-ssl-dual-auth.yaml | podman-compose -f- up
```

## Configure a channel auth record for the SSL cert, maps certs with CN=app to user app.
```
echo "SET CHLAUTH('DEV.APP.SVRCONN') TYPE(SSLPEERMAP) SSLPEER('CN=app') MCAUSER('app') ACTION(REPLACE)" | podman exec -i QM1 /bin/bash -c runmqsc
```

## Test local IBM MQ instance with camel route

Requires jbang with camel
Tested with Java 21 (uses jakarta package name). Run the route:

```
JDK_JAVA_OPTIONS="-Djavax.net.ssl.trustStore=/tmp/ca-data/certs/truststore.p12 -Djavax.net.ssl.trustStorePassword=foobar -Djavax.net.ssl.keyStore=/tmp/ca-data/certs/app.p12 -Djavax.net.ssl.keyStorePassword=foobar" camel run camel-mq-client/MQRoute.java --dep=com.ibm.mq:com.ibm.mq.jakarta.client:9.4.2.0 --profile dev-ssl
```


## Clean up

```
cat podman/podman-compose-plain-ssl-dual-auth.yaml | podman-compose -f- down -v
```