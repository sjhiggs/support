#!/bin/bash

cd "$(dirname "$0")"

KAFKA_VERSION=${KAFKA_VERSION:-4.3.1}
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION

eval rm -rf /tmp/controller-{0..5}
eval rm -rf /tmp/kafka-{0..5}
eval rm -rf /tmp/kraft-broker-logs-{0..5}
eval rm -rf /tmp/kraft-controller-logs-{0..5}
eval rm -rf /tmp/kraft-combined-logs-{0..5}

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --standalone --config ../config/kraft-noauth/controller-0.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-noauth/controller-1.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-noauth/controller-2.properties

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-noauth/broker-3.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-noauth/broker-4.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-noauth/broker-5.properties
