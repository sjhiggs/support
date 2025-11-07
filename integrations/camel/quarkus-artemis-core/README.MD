# Run

## Initialization

edit Artemis URL in src/main/resources/application.properties

## Dev mode

~~~
mvn clean quarkus:dev
~~~

## JVM podman-compose

./mvnw clean compile
podman build -f src/main/docker/Dockerfile.jvm -t camel-quarkus-artemis-core:1.0.0
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up

## Native podman-compose

./mvnw clean package -Dnative
podman build -f src/main/docker/Dockerfile.native -t camel-quarkus-artemis-core:1.0.0
cat src/main/podman-compose/podman-compose-conn-router.yaml | podman-compose -f- up


## Native mode

~~~
./mvnw clean package -Dnative
./target/camel-artemis-core-client-1.0.0-runner
~~~
