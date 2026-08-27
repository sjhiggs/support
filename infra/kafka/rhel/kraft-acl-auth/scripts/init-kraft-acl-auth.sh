#!/bin/bash

cd "$(dirname "$0")"

KAFKA_VERSION=${KAFKA_VERSION:-4.3.1}
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION

eval rm -rf /tmp/controller-{0..5}
eval rm -rf /tmp/kafka-{0..5}
eval rm -rf /tmp/kraft-broker-logs-{0..5}
eval rm -rf /tmp/kraft-controller-logs-{0..5}
eval rm -rf /tmp/kraft-combined-logs-{0..5}

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --standalone --config ../config/kraft-acl-auth/controller-0.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-acl-auth/controller-1.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-acl-auth/controller-2.properties

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-acl-auth/broker-3.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-acl-auth/broker-4.properties
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-acl-auth/broker-5.properties
