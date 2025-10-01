# The quick instructions:

## Step 1: start environment:

```
export DEBEZIUM_VERSION=2.7
export DEBEZIUM_CONNECTOR_VERSION=2.7.3.Final
podman-compose up --build -d
```

```
export DEBEZIUM_VERSION=2.2
export DEBEZIUM_CONNECTOR_VERSION=2.2.1.Final
podman-compose up --build -d
```

## Step 2: start the connector and load test
```
./run-test.sh
```

## Step 3: evaluate results

look for the `debezium_metrics_milliseconds_behind_source` metric

```
curl -s localhost:9404/metrics  | grep debezium
```

## Step 5: shut down

```
podman-compose down --timeout 0 -v
```



