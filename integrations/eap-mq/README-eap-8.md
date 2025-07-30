# Standalone: Configure Test EAP application as a client to IBM-MQ

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


```
git clone -b 8.0.x https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-8.0.patch | git -C /tmp/jboss-eap-quickstarts apply 
cd /tmp/jboss-eap-quickstarts/remote-helloworld-mdb
mvn clean package wildfly:deploy -Dcheckstyle.skip
```

```
curl http://localhost:8080/remote-helloworld-mdb/HelloWorldMDBServletClient
```


# Domain: Configure Test EAP application as a client to IBM-MQ

The process is similar to standalone mode, commands have been adjusted for domain mode.


## Run EAP 
Run EAP in domain mode, starts a domain/host controller and two servers
```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
$EAP_HOME/bin/domain.sh
```

## Deploy rar and configure EAP

Deploy the rar to servers in the "main-server-group" (default is a two servers, server-one and server-two)
```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
export CONTAINER_NAME=QM1
podman cp $CONTAINER_NAME:./opt/mqm/java/lib/jca/wmq.jakarta.jmsra.rar /tmp/
$EAP_HOME/bin/jboss-cli.sh -c "deploy /tmp/wmq.jakarta.jmsra.rar --server-groups=main-server-group"
$EAP_HOME/bin/jboss-cli.sh -c --file=cli/8/configure-domain.cli  --echo-command
```

If MQ is configured for SSL (mTLS):

```
$EAP_HOME/bin/jboss-cli.sh -c --file=cli/8/configure-domain-ssl.cli  --echo-command
```

## Test

In addition to standalone scripts, update pom.xml for domain configuration, deploy to main-server-group servers
```
git clone -b 8.0.x https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-8.0.patch | git -C /tmp/jboss-eap-quickstarts apply
cat patch/domain-jboss-eap-8.0.patch | git -C /tmp/jboss-eap-quickstarts apply
```

If MQ is configured for SSL (mTLS), don't try to send passwords:
```
cat patch/domain-jboss-eap-8.0-mtls.patch | git -C /tmp/jboss-eap-quickstarts apply
```

```
pushd /tmp/jboss-eap-quickstarts/remote-helloworld-mdb
mvn clean package wildfly:deploy -Dcheckstyle.skip
```

```
curl http://127.0.0.1:8080/remote-helloworld-mdb/HelloWorldMDBServletClient
```

Server logs are located at:
```
cat $EAP_HOME/domain/servers/server-one/log/server.log
cat $EAP_HOME/domain/servers/server-two/log/server.log
```


MQ CLI show SSL auth for the connections:

```
echo "DISPLAY CHSTATUS(DEV.APP.SVRCONN) SSLPEER SSLCERTI" | podman exec -i QM1 /bin/bash -c runmqsc
```
