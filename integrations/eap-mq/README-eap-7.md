# Configure Test EAP application as a client to IBM-MQ

https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.4/html-single/configuring_messaging/index#deploy_the_ibm_mq_resource_adapter

## Run IBM MQ

Note: see infra/ibm-mq podman project for IBM MQ setup.


## Run EAP

```
export EAP_HOME=/redhat/eap/jboss-eap-7.4
$EAP_HOME/bin/standalone.sh -c standalone-full.xml
```

## Copy the WMQ rar from a podman container to the eap instance

```
export EAP_HOME=/redhat/eap/jboss-eap-7.4
export CONTAINER_NAME=QM1
podman cp $CONTAINER_NAME:./opt/mqm/java/lib/jca/wmq.jmsra.rar  $EAP_HOME/standalone/deployments/
```

## Configure EAP 

Use the JBoss CLI to configure rar (init).  Note: update IP address in install-m.  Note: update IP address in install-mq.cli as needed.

```
export EAP_HOME=/redhat/eap/jboss-eap-7.4
$EAP_HOME/bin/jboss-cli.sh -c --file=cli/7/configure.cli  --echo-command
```

Restart EAP.

## Add a test client


```
git clone -b 7.4.x https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-7.4.patch | git -C /tmp/jboss-eap-quickstarts apply 
cd /tmp/jboss-eap-quickstarts/helloworld-mdb
mvn clean package wildfly:deploy -Dcheckstyle.skip

```
curl http://localhost:8080/helloworld-mdb/HelloWorldMDBServletClient
curl http://localhost:8080/helloworld-mdb/HelloWorldMDBServletClient?topic
```

