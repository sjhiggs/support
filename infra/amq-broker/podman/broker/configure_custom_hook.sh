#!/bin/sh
set -e
INSTANCE_DIR=$1

echo ""
echo "===================="
echo "START configure hook"
echo "calling configure_custom_config.sh..."
$AMQ_HOME/bin/configure_custom_config.sh $INSTANCE_DIR

echo "Copying Config files from custom dir"
cp -v $AMQ_HOME/custom/etc/* ${INSTANCE_DIR}/etc/

echo "updating bootstrap.xml for dual authentication..."

sed -i 's/domain="activemq"/domain="PropertiesLogin" certificate-domain="CertLogin"/' ${INSTANCE_DIR}/etc/bootstrap.xml

echo "END configure hook"
echo "===================="
echo ""
