#!/bin/bash

cd "$(dirname "$0")"

export KAFKA_DIR=/tmp/kafka-3.9.0

eval rm -rf /tmp/kafka-{0..5}
eval rm -rf /tmp/kraft-combined-logs-*

$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --standalone --config ../config/kraft-dual-tls-sasl/server-0.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-dual-tls-sasl/server-1.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'
$KAFKA_DIR/bin/kafka-storage.sh format --cluster-id q6Wklx3BQF6RxKTRElZYUA --no-initial-controllers --config ../config/kraft-dual-tls-sasl/server-2.properties --add-scram 'SCRAM-SHA-512=[name=admin,password=secret]'

