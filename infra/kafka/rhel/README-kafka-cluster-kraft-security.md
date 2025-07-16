# Install a KRAFT cluster with SSL and SASL


## Init

Use the "ca" project to initialize a new CA, Issuing CA, and broker certs:

```
./scripts/kafka-get.sh --kafka-version=3.9.0
```

```
mkdir /tmp/ca-data
../../ca/scripts/create.sh
../../ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="IP:127.0.0.1,DNS:localhost"
../../ca/scripts/cert-client.sh --cn=admin
```

Create truststore, client auth pkcs12, server pkc12:

```
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar
```

## Start with TLS, PLAIN for controller listener and  SCRAM-SHA-512 for everything else


```
./scripts/init-kraft-tls-sasl.sh
./scripts/start-cluster-kraft-tls-sasl.sh
```

## Add quorum members

```
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090,127.0.0.1:10091,127.0.0.1:10092 --command-config config/kraft-tls-sasl/controller-admin.properties describe --re --hu
```

```
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090  --command-config config/kraft-tls-sasl/controller-1.properties add-controller 
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090  --command-config config/kraft-tls-sasl/controller-2.properties add-controller 
```

```
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090,127.0.0.1:10091,127.0.0.1:10092 --command-config config/kraft-tls-sasl/controller-admin.properties describe --re --hu
```


## Client Test

Add SCRAM-SHA-512 auth for user alice, using the admin login to the clients port
```
$KAFKA_DIR/bin/kafka-configs.sh --bootstrap-server localhost:11090 --alter --add-config 'SCRAM-SHA-512=[password=alice-secret]'  --entity-type users  --entity-name alice --command-config config/kraft-tls-sasl/admin.properties
```

Allow alice permissions "create/read/write" on the foo topic
```
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --add --allow-principal User:alice --operation Read --operation Write --operation Create --topic foo --command-config config/kraft-tls-sasl/admin.properties
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --add --allow-principal User:alice --operation Read --group foo-consumer-group --command-config config/kraft-tls-sasl/admin.properties
```

```

$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090  --create --topic foo --partitions 3 --replication-factor 3 --command-config ./config/kraft-tls-sasl/alice.properties
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --producer.config ./config/kraft-tls-sasl/alice.properties --topic foo
$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --consumer.config ./config/kraft-tls-sasl/alice.properties --topic foo --group foo-consumer-group --from-beginning
```

## Shut down

```
./scripts/stop-cluster-kraft.sh
```

## TODO: Client Cert Authentication

