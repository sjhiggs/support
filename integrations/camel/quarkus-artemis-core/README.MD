# Run

## Initialization

Create certificates for broker TLS:

```
./src/main/amq/create-certs.sh
```

## Dev mode

(requires a running broker)

```
mvn clean quarkus:dev -Djvm.args="-Djavax.net.ssl.trustStore=/tmp/ca-data/certs/truststore.p12 -Djavax.net.ssl.trustStorePassword=foobar"
```

## JVM podman-compose

example with a running broker and a connection router:

```
./mvnw clean package -Dquarkus.profile=podman
podman build -f src/main/docker/Dockerfile.jvm -t camel-quarkus-artemis-core:1.0.0 .
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up
```

//N.B. - make sure the containers are cleaned up (podman-compose -f- down)

## Native podman-compose

example with a running broker and a connection router:

```
./mvnw clean package -Dquarkus.profile=podman -Dnative
podman build -f src/main/docker/Dockerfile.native -t camel-quarkus-artemis-core:1.0.0 .
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up
```

//N.B. - make sure the containers are cleaned up (podman-compose -f- down)

## Native mode

(requires a running broker)

```
./mvnw clean package -Dnative
./target/camel-artemis-core-client-1.0.0-runner
```
