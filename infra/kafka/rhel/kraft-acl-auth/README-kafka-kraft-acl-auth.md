# KRaft cluster with mTLS inter-node auth, SASL clients, and ACL enforcement

This scenario demonstrates a KRaft cluster with a hybrid security model:

- **mTLS (SSL client certificate authentication)** for all inter-broker and inter-controller traffic
- **SASL_SSL (SCRAM-SHA-512)** for external client traffic
- **Superusers** for broker/controller identities (bypass the authorizer)
- **`allow.everyone.if.no.acl.found=false`** (default deny — clients must have explicit ACLs)

## Security model

| Listener | Protocol | Auth mechanism | Identity | Ports |
|---|---|---|---|---|
| CONTROLLER | SSL | mTLS (client cert) | `myserver` (extracted from cert CN) | 10090-10092 |
| INTERBROKER | SSL | mTLS (client cert) | `myserver` (extracted from cert CN) | 9090-9092 |
| CLIENTS | SASL_SSL | SCRAM-SHA-512 | per-user (`admin`, `alice`, etc.) | 11090-11092 |

**How it works:**

- Controllers and brokers all use the same TLS certificate (`myserver.p12`). The CONTROLLER and
  INTERBROKER listeners require client certificate authentication (`ssl.client.auth=required`).
- The certificate DN `CN=myserver,OU=Support,O=FOO ORG,...` is mapped to principal `myserver`
  via `ssl.principal.mapping.rules=RULE:^CN=(.*?),OU=.*$/$1/,DEFAULT`.
- `super.users=User:myserver;User:admin` — the `myserver` identity (used by all inter-node
  SSL connections) and the `admin` SCRAM identity both bypass the authorizer entirely.
- `allow.everyone.if.no.acl.found=false` — any client without an explicit ACL is denied.
  This is the strongest authorization posture: clients must be granted specific permissions.
- The CLIENTS listener uses SASL_SSL with SCRAM-SHA-512. Clients authenticate with
  username/password and are authorized by ACLs.

**Why superusers + default deny is the strongest model:**

| | No superusers + default allow | Superusers + default deny |
|---|---|---|
| Unauthenticated access | Denied (all listeners require auth) | Denied (all listeners require auth) |
| New client, no ACLs | **Allowed** on all resources without ACLs | **Denied** on everything |
| Resources without ACLs | Open to any authenticated user | Locked down — only superusers can access |
| Broker/controller auth | Rely on default-allow for cluster ops | Bypass authorizer via `super.users` |
| Attack surface | Must proactively ACL every resource | Only superusers bypass checks |


## Init

Use the "ca" project to create TLS certificates:

```
export KAFKA_VERSION=4.3.1
../scripts/kafka-get.sh --kafka-version=$KAFKA_VERSION
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION
```

```
mkdir /tmp/ca-data
../../../ca/scripts/create.sh
../../../ca/scripts/cert-server.sh --cn=myserver --subject-alt-name="IP:127.0.0.1,DNS:localhost"
../../../ca/scripts/cert-client.sh --cn=admin
```

Create truststore and server PKCS12:

```
cat /tmp/ca-data/certs/myserver.pem /tmp/ca-data/issuing/ca.issuing.pem > /tmp/ca-data/certs/myserver.combined.pem
openssl pkcs12 -export -nokeys -in /tmp/ca-data/ca/ca.pem -out /tmp/ca-data/certs/truststore.p12 -passout pass:foobar
keytool -import -file /tmp/ca-data/ca/ca.pem  -keystore /tmp/ca-data/certs/truststore.p12 -storetype PKCS12 -storepass foobar -noprompt
openssl pkcs12 -export -name myServer -noiter -nomaciter -in /tmp/ca-data/certs/myserver.combined.pem -inkey /tmp/ca-data/certs/myserver.key -out /tmp/ca-data/certs/myserver.p12 -passin pass:foobar -passout pass:foobar
```

## Start the cluster

```
./scripts/init-kraft-acl-auth.sh
./scripts/start-cluster-kraft-acl-auth.sh
```

The init script bootstraps the `admin` SCRAM credential via `--add-scram` during `kafka-storage.sh format`.

## Add quorum members

```
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090  --command-config config/kraft-acl-auth/controller-1.properties add-controller
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090  --command-config config/kraft-acl-auth/controller-2.properties add-controller
$KAFKA_DIR/bin/kafka-metadata-quorum.sh --bootstrap-controller 127.0.0.1:10090,127.0.0.1:10091,127.0.0.1:10092 --command-config config/kraft-acl-auth/controller-admin.properties describe --re --hu
```

The `add-controller` commands use the controller properties files directly as `--command-config`
because they contain the embedded SSL client config (`security.protocol=SSL`). The controller-admin
properties file uses the `myserver.p12` keystore for mTLS authentication to the CONTROLLER listener.

## Client test

Add SCRAM credentials for user `alice` and grant ACLs on topic `foo`:

```
$KAFKA_DIR/bin/kafka-configs.sh --bootstrap-server localhost:11090 --alter --add-config 'SCRAM-SHA-512=[password=alice-secret]' --entity-type users --entity-name alice --command-config config/kraft-acl-auth/admin.properties
```

```
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --add --allow-principal User:alice --operation Read --operation Write --operation Create --topic foo --command-config config/kraft-acl-auth/admin.properties
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --add --allow-principal User:alice --operation Read --group foo-consumer-group --command-config config/kraft-acl-auth/admin.properties
```

Create topic, produce, and consume as alice:

```
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090 --create --topic foo --partitions 3 --replication-factor 3 --command-config ./config/kraft-acl-auth/alice.properties
```

```
$KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --command-config ./config/kraft-acl-auth/alice.properties --topic foo
```

```
$KAFKA_DIR/bin/kafka-console-consumer.sh --bootstrap-server=127.0.0.1:11090,127.0.0.1:11091,127.0.0.1:11092 --command-config ./config/kraft-acl-auth/alice.properties --topic foo --group foo-consumer-group --from-beginning
```

## Verify ACL enforcement

With `allow.everyone.if.no.acl.found=false`, alice is denied on any resource she doesn't have
an explicit ACL for:

```
# alice can produce to topic 'foo' (has Write ACL)
echo "acl-test" | $KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server=127.0.0.1:11090 --command-config ./config/kraft-acl-auth/alice.properties --topic foo

# alice CANNOT create a topic she has no ACL for
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090 --create --topic unauthorized-topic --partitions 1 --replication-factor 1 --command-config ./config/kraft-acl-auth/alice.properties
# Expected: TopicAuthorizationException

# alice CANNOT produce to a topic she has no ACL for
echo "test" | $KAFKA_DIR/bin/kafka-console-producer.sh --bootstrap-server=127.0.0.1:11090 --command-config ./config/kraft-acl-auth/alice.properties --topic bar
# Expected: TopicAuthorizationException

# alice CANNOT list ACLs (no DESCRIBE on Cluster)
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --list --command-config config/kraft-acl-auth/alice.properties
# Expected: ClusterAuthorizationException

# admin CAN do all of the above (superuser — bypasses all authorization)
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090 --create --topic bar --partitions 3 --replication-factor 3 --command-config config/kraft-acl-auth/admin.properties
$KAFKA_DIR/bin/kafka-acls.sh --bootstrap-server 127.0.0.1:11090 --list --command-config config/kraft-acl-auth/admin.properties

# Replication works (RF=3, all brokers in ISR)
$KAFKA_DIR/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:11090 --describe --topic foo --command-config config/kraft-acl-auth/admin.properties
```


## Shut down

```
./scripts/stop-cluster-kraft.sh
```
