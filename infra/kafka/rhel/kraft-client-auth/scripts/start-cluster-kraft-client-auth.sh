#!/bin/bash

cd "$(dirname "$0")"

KAFKA_VERSION=${KAFKA_VERSION:-4.3.1}
export KAFKA_DIR=/tmp/kafka-$KAFKA_VERSION

LOG_DIR=/tmp/controller-0/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/controller-0.properties
LOG_DIR=/tmp/controller-1/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/controller-1.properties
LOG_DIR=/tmp/controller-2/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/controller-2.properties

LOG_DIR=/tmp/kafka-3/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/broker-3.properties
LOG_DIR=/tmp/kafka-4/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/broker-4.properties
LOG_DIR=/tmp/kafka-5/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/kraft-client-auth/broker-5.properties
