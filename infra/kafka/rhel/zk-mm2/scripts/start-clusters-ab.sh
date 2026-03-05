#!/bin/bash

cd "$(dirname "$0")"

export KAFKA_DIR=/tmp/kafka-3.9.0

LOG_DIR=/tmp/zookeeper-0/logs $KAFKA_DIR/bin/zookeeper-server-start.sh -daemon ../config/cluster-a/zookeeper-0.properties
LOG_DIR=/tmp/kafka-0/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-a/server-0.properties
LOG_DIR=/tmp/kafka-1/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-a/server-1.properties
LOG_DIR=/tmp/kafka-2/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-a/server-2.properties

LOG_DIR=/tmp/zookeeper-1/logs $KAFKA_DIR/bin/zookeeper-server-start.sh -daemon ../config/cluster-b/zookeeper-1.properties
LOG_DIR=/tmp/kafka-3/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-b/server-3.properties
LOG_DIR=/tmp/kafka-4/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-b/server-4.properties
LOG_DIR=/tmp/kafka-5/logs $KAFKA_DIR/bin/kafka-server-start.sh -daemon ../config/cluster-b/server-5.properties

