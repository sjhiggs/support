
```
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.16.0/opentelemetry-javaagent.jar -P /tmp/opentelemetry/
```


```
JDK_JAVA_OPTIONS="-javaagent:/tmp/opentelemetry/opentelemetry-javaagent.jar -Dotel.metrics.exporter=none -Dotel.traces.exporter=console -Dotel.logs.exporter=none" camel run  --dep=camel-opentelemetry2  camel-jbang/MyRoute.java camel-jbang/MyRoute.properties
```


```
curl http://localhost:8080
```
