#!/bin/bash

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Testing Oracle Database Changes"
echo "=========================================="
echo ""

# Check if Oracle container is running
if ! podman ps | grep -q "oracle"; then
    echo "ERROR: Oracle container is not running"
    echo "Start services first: ./scripts/podman-start.sh"
    exit 1
fi

echo "This script will make changes to the Oracle database and"
echo "demonstrate Debezium change data capture."
echo ""
echo "Operations:"
echo "  1. Insert a new product"
echo "  2. Update product inventory"
echo "  3. Insert a new customer"
echo "  4. Insert a new order"
echo "  5. Update order status"
echo "  6. Delete a product inventory record"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read -r

echo ""
echo "Executing database changes..."
echo ""

# Execute SQL changes
podman exec -i oracle sqlplus -s debezium/dbz@XEPDB1 <<'EOF'
SET SERVEROUTPUT ON;
SET FEEDBACK ON;

-- 1. Insert a new product
BEGIN
    DBMS_OUTPUT.PUT_LINE('1. Inserting new product: "USB-C Cable"');
END;
/

INSERT INTO products (id, name, description, weight, created_at)
VALUES (NULL, 'USB-C Cable', '6ft braided USB-C cable', 0.15, CURRENT_TIMESTAMP);

SELECT 'Product inserted with ID: ' || id FROM products WHERE name = 'USB-C Cable';
COMMIT;

-- 2. Update product inventory
BEGIN
    DBMS_OUTPUT.PUT_LINE('2. Updating inventory for product 102 (car battery)');
END;
/

UPDATE products_on_hand
SET quantity = quantity - 2,
    last_updated = CURRENT_TIMESTAMP
WHERE product_id = 102;

SELECT 'Updated inventory for product ' || product_id || ', new quantity: ' || quantity
FROM products_on_hand WHERE product_id = 102;
COMMIT;

-- 3. Insert a new customer
BEGIN
    DBMS_OUTPUT.PUT_LINE('3. Inserting new customer');
END;
/

INSERT INTO customers (id, first_name, last_name, email, created_at)
VALUES (NULL, 'John', 'Doe', 'john.doe@example.com', CURRENT_TIMESTAMP);

SELECT 'Customer inserted with ID: ' || id FROM customers WHERE email = 'john.doe@example.com';
COMMIT;

-- 4. Insert a new order
BEGIN
    DBMS_OUTPUT.PUT_LINE('4. Inserting new order');
END;
/

INSERT INTO orders (id, order_date, purchaser, quantity, product_id, status)
VALUES (NULL, CURRENT_DATE, 1001, 3, 104, 'PENDING');

SELECT 'Order inserted with ID: ' || id FROM orders WHERE purchaser = 1001 AND product_id = 104;
COMMIT;

-- 5. Update order status
BEGIN
    DBMS_OUTPUT.PUT_LINE('5. Updating order status to SHIPPED');
END;
/

UPDATE orders
SET status = 'SHIPPED'
WHERE purchaser = 1002 AND status = 'PENDING';

SELECT 'Updated ' || SQL%ROWCOUNT || ' order(s) to SHIPPED' FROM dual;
COMMIT;

-- 6. Delete inventory record for product 106 (zero quantity)
BEGIN
    DBMS_OUTPUT.PUT_LINE('6. Deleting inventory record for product 106');
END;
/

DELETE FROM products_on_hand WHERE product_id = 106;

SELECT 'Deleted inventory for product 106' FROM dual;
COMMIT;

-- Show summary
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Database changes complete!');
    DBMS_OUTPUT.PUT_LINE('========================================');
END;
/

EXIT;
EOF

echo ""
echo "=========================================="
echo "Database Changes Applied!"
echo "=========================================="
echo ""
echo "These changes should now appear in Kafka topics."
echo ""
echo "View the change events:"
echo ""
echo "1. Products table changes:"
echo "   podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --topic oracle.DEBEZIUM.PRODUCTS \\"
echo "     --from-beginning"
echo ""
echo "2. Inventory changes:"
echo "   podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --topic oracle.DEBEZIUM.PRODUCTS_ON_HAND \\"
echo "     --from-beginning"
echo ""
echo "3. Customer changes:"
echo "   podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --topic oracle.DEBEZIUM.CUSTOMERS \\"
echo "     --from-beginning"
echo ""
echo "4. Order changes:"
echo "   podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --topic oracle.DEBEZIUM.ORDERS \\"
echo "     --from-beginning"
echo ""
echo "Watch all topics in real-time:"
echo "   podman exec kafka-0 /opt/kafka/bin/kafka-console-consumer.sh \\"
echo "     --bootstrap-server localhost:9092 \\"
echo "     --whitelist 'oracle.DEBEZIUM.*' \\"
echo "     --from-beginning"
echo ""
