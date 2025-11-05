# Run

## Initialization

edit Artemis URL in src/main/resources/application.properties

## Dev mode

~~~
mvn clean quarkus:dev
~~~


## Native mode

~~~
quarkus build --native
./target/camel-artemis-core-client-1.0.0-runner
~~~
