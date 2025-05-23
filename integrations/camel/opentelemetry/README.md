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
JDK_JAVA_OPTIONS="-javaagent:/tmp/opentelemetry/opentelemetry-javaagent.jar -Dotel.metrics.exporter=none -Dotel.traces.exporter=otlp,console -Dotel.logs.exporter=none" camel run  --dep=camel-opentelemetry2  camel-jbang/MyRoute.java camel-jbang/MyRoute.properties
```


## Test endpoint
```
curl http://localhost:8080
```


