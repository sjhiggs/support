ARG STRIMZI_VERSION=latest-kafka-3.9.0
FROM quay.io/strimzi/kafka:${STRIMZI_VERSION}

ARG DEBEZIUM_CONNECTOR_VERSION=2.7.3.Final
ENV KAFKA_CONNECT_PLUGIN_PATH=/tmp/connect-plugins
ENV KAFKA_CONNECT_LIBS=/opt/kafka/libs

RUN echo `whoami`

RUN mkdir $KAFKA_CONNECT_PLUGIN_PATH &&\
    cd $KAFKA_CONNECT_PLUGIN_PATH &&\
    curl -sfSL https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/${DEBEZIUM_CONNECTOR_VERSION}/debezium-connector-mongodb-${DEBEZIUM_CONNECTOR_VERSION}-plugin.tar.gz | tar xz

USER root
RUN mkdir -p $KAFKA_HOME/custom-config
COPY metrics-config.json $KAFKA_HOME/custom-config/metrics-config.json
COPY strimzi-connect.properties /tmp/strimzi-connect.properties

USER kafka
