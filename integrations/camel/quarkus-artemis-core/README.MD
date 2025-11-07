# Run

## Initialization

Create certificates for broker TLS:

```
./src/main/amq/create-certs.sh
```

## Dev mode

(requires a running broker)

```
mvn clean quarkus:dev
```

## JVM podman-compose

example with a running broker and a connection router:

```
./mvnw clean compile
podman build -f src/main/docker/Dockerfile.jvm -t camel-quarkus-artemis-core:1.0.0
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up
```

## Native podman-compose

example with a running broker and a connection router:

```
./mvnw clean package -Dnative
podman build -f src/main/docker/Dockerfile.native -t camel-quarkus-artemis-core:1.0.0
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up
```

## Native mode

(requires a running broker)

```
./mvnw clean package -Dnative
./target/camel-artemis-core-client-1.0.0-runner
```
