# Camel with Opentelemetry

Test camel integration with opentelemetry

## Download java agent
```
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.16.0/opentelemetry-javaagent.jar -P /tmp/opentelemetry/
```

## Run sample route with opentelemetry output to logs
```
JDK_JAVA_OPTIONS="-javaagent:/tmp/opentelemetry/opentelemetry-javaagent.jar -Dotel.metrics.exporter=none -Dotel.traces.exporter=console -Dotel.logs.exporter=none" camel run  --dep=camel-opentelemetry2  camel-jbang/MyRoute.java camel-jbang/MyRoute.properties
```

## Run a sample route with opentelemetry output to a simple opentelemetry collector

```
podman run --rm  -p 127.0.0.1:4317:4317   -p 127.0.0.1:4318:4318   -p 127.0.0.1:55679:55679   otel/opentelemetry-collector-contrib:latest
```

```
JDK_JAVA_OPTIONS="-javaagent:/tmp/opentelemetry/opentelemetry-javaagent.jar -Dotel.metrics.exporter=otlp,console -Dotel.traces.exporter=otlp -Dotel.logs.exporter=otlp -Dotel.exporter.otlp.endpoint=http://localhost:4318 -Dotel.service.name=myjava-app" camel run  --dep=camel-opentelemetry2  camel-jbang/MyRoute.java camel-jbang/MyRoute.properties

```


Use opentelemetry+elasticsaerch instead:

Credit for podman environment install: https://medium.com/@davidsilwal/implementing-production-ready-observability-with-elastic-stack-and-opentelemetry-collector-4924b842fe48

```
podman pull elasticsearch:9.0.1
podman run -d --name elasticsearch --memory 2048m  -p 9200:9200 -p 9300:9300  -e "discovery.type=single-node"  -e "xpack.security.enabled=false"  elasticsearch:9.0.1
```


## Test endpoint
```
curl http://localhost:8080
```


