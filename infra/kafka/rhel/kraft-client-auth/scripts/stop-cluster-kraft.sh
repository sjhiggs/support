#!/bin/bash

cd "$(dirname "$0")"

KAFKA_VERSION=${KAFKA_VERSION:-4.3.1}
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION

$KAFKA_DIR/bin/kafka-server-stop.sh --process-role=broker
sleep 5
$KAFKA_DIR/bin/kafka-server-stop.sh --process-role=controller
