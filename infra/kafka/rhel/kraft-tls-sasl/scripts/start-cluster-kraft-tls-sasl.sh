#!/bin/bash

cd "$(dirname "$0")"

export KAFKA_DIR=/tmp/kafka-3.9.0

LOG_DIR=/tmp/controller-0/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/controller-0.properties
LOG_DIR=/tmp/controller-1/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/controller-1.properties
LOG_DIR=/tmp/controller-2/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/controller-2.properties

LOG_DIR=/tmp/kafka-3/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/broker-3.properties
LOG_DIR=/tmp/kafka-4/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/broker-4.properties
LOG_DIR=/tmp/kafka-5/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-tls-sasl/broker-5.properties
