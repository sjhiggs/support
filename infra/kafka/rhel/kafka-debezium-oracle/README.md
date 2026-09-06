# Kafka + Debezium + Oracle Test Environment

Test environment for **Debezium change data capture (CDC)** with **Apache Kafka** and **Oracle Database**.

Stack: Kafka cluster (3 nodes) + Debezium Connect (2 workers) + Oracle XE with test data (products, customers, orders).

## Prerequisites

- **podman-compose** or **docker-compose**
- Minimum 8GB RAM, ~15GB disk space

```bash
sudo dnf install podman-compose
```

## Quick Start

### 1. Start Everything

```bash
./scripts/podman-start.sh
```

First startup takes 2-3 minutes while Oracle initializes.

### 2. Register the Debezium Connector

```bash
./scripts/register-connector.sh
```

### 3. Run a Basic Test

```bash
./scripts/test-update.sh
```

This inserts, updates, and deletes test data in Oracle.

### 4. Verify Changes Captured

View events from the products table:
```bash
podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka-0:9092 \
  --topic oracle.DEBEZIUM.PRODUCTS \
  --from-beginning
```

**Note:** Use `kafka-0:9092` (not `localhost:9092`) as the bootstrap server when running commands inside the Kafka container.

You should see JSON change events for each database operation.

## Stop and Cleanup

```bash
# Stop (keep data)
./scripts/podman-stop.sh

# Stop and remove all data
podman-compose down -v
```

## Manual Testing

Connect to Oracle and make changes:
```bash
podman exec -it oracle sqlplus debezium/dbz@XEPDB1

SQL> UPDATE products SET weight = 10.5 WHERE id = 101;
SQL> COMMIT;
SQL> EXIT;
```

Check connector status:
```bash
curl http://localhost:8083/connectors/oracle-inventory-connector/status | python3 -m json.tool
```

View all topics:
```bash
podman exec kafka-0 /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-0:9092 --list
```

## Configuration

- Component versions: `versions.env`
- Connector config: `config/debezium/register-oracle.json`
- Database user: c##dbzuser/dbz (CDB common user), oracle/oracle (SYS)
- Ports: Kafka (9092-9094), Oracle (1521), Debezium (8083-8084)

## Notes

- Oracle runs in **archive log mode** (required for CDC)
- Connector connects to CDB (XE) and monitors PDB (XEPDB1) tables
- Tasks.max is set to 1 (Oracle connector limitation)
