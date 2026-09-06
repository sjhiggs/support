ARG DEBEZIUM_VERSION=3.0
FROM quay.io/debezium/connect:${DEBEZIUM_VERSION}

# Oracle JDBC driver configuration
ARG ORACLE_JDBC_VERSION=21.6.0.0
ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc \
    MAVEN_DEP_DESTINATION=$KAFKA_HOME/libs \
    ORACLE_JDBC_REPO="com/oracle/database/jdbc" \
    ORACLE_JDBC_GROUP="ojdbc8" \
    ORACLE_JDBC_VERSION=${ORACLE_JDBC_VERSION} \
    ORACLE_JDBC_MD5=312e6f4ec9932bbf74a4461669970c4b

# Download Oracle JDBC driver from Maven Central
RUN docker-maven-download central "$ORACLE_JDBC_REPO" "$ORACLE_JDBC_GROUP" "$ORACLE_JDBC_VERSION" "$ORACLE_JDBC_MD5"

USER kafka
