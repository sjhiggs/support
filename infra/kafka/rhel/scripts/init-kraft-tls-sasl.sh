#!/bin/bash

cd "$(dirname "$0")"

export KAFKA_DIR=/tmp/kafka-3.9.0

eval rm -rf /tmp/controller-{0..5}
eval rm -rf /tmp/kafka-{0..5}
eval rm -rf /tmp/kraft-broker-logs-{0..5}
eval rm -rf /tmp/kraft-controller-logs-{0..5}
eval rm -rf /tmp/kraft-combined-logs-{0..5}

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --standalone --config ../config/kraft-tls-sasl/controller-0.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-tls-sasl/controller-1.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-tls-sasl/controller-2.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-tls-sasl/broker-3.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-tls-sasl/broker-4.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-tls-sasl/broker-5.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'

