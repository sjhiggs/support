# Configure Test EAP application as a client to IBM-MQ

https://access.redhat.com/documentation/en-us/red_hat_jboss_enterprise_application_platform/7.4/html-single/configuring_messaging/index#deploy_the_ibm_mq_resource_adapter

## Run IBM MQ

Note: see infra/ibm-mq podman project for IBM MQ setup.


## Run EAP

```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
$EAP_HOME/bin/standalone.sh -c standalone-full.xml
```

## Copy the WMQ rar from a podman container to the eap instance and configure EAP

```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
export CONTAINER_NAME=QM1
podman cp $CONTAINER_NAME:./opt/mqm/java/lib/jca/wmq.jakarta.jmsra.rar  $EAP_HOME/standalone/deployments/
$EAP_HOME/bin/jboss-cli.sh -c --file=cli/8/configure.cli  --echo-command
```


Restart EAP.

## Add a test client


TODO: NOT working yet!
```
git clone -b 8.0.x https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-8.0.patch | git -C /tmp/jboss-eap-quickstarts apply 
cd /tmp/jboss-eap-quickstarts/remote-helloworld-mdb
mvn clean package wildfly:deploy -Dcheckstyle.skip

```
curl http://localhost:8080/remote-helloworld-mdb/HelloWorldMDBServletClient
```

