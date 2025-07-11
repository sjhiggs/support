#!/bin/bash

cd "$(dirname "$0")"

export KAFKA_DIR=/tmp/kafka-3.9.0

LOG_DIR=/tmp/kafka-0/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-dual-tls-sasl/server-0.properties
LOG_DIR=/tmp/kafka-1/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-dual-tls-sasl/server-1.properties
LOG_DIR=/tmp/kafka-2/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-dual-tls-sasl/server-2.properties
