# Camel with Opentelemetry

Demonstrates camel with opentelemetry, with a custom span decorator to control the format of the fields sent to opentelemetry.  For example, this project uses a decorator that sets the "operation name" with the following:

```
            return "TEST " + super.getOperationName(exchange, endpoint) + " "
                    + URISupport.normalizeUriAsURI(endpoint.getEndpointBaseUri()).getPath();
```

Which results in the following received by the openteletry server for the span:

```
            Name: TEST GET /route/health
```

This is accomplished by registering a custom Span Decorator for the "http" component.  The decorator is registered by adding the class name a file in the META-INF/services directory (Java Service Loader).  Thereafeter, the decorator will be used when formatting the span information.

## Run a sample route with opentelemetry output to a simple opentelemetry collector

```
podman run --rm  -p 127.0.0.1:4317:4317   -p 127.0.0.1:4318:4318   -p 127.0.0.1:55679:55679   otel/opentelemetry-collector-contrib:latest
```

```
mvn clean quarkus:dev
```


## Test endpoint
```
curl http://localhost:8080/routes/health
```


