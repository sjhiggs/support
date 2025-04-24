# Configure Test EAP application as a client to AMQ

## Run AMQ

See infra/amq-broker project

## Run EAP

```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
$EAP_HOME/bin/standalone.sh -c standalone-full.xml -b 127.0.0.1
```


## Configure Remote Connection
```
export EAP_HOME=/redhat/eap/jboss-eap-8.0
$EAP_HOME/bin/jboss-cli.sh --connect --file=cli/8/configure.cli
```

## Create MDB and test

```
git clone -b 8.0.x --single-branch https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-8.patch | git -C /tmp/jboss-eap-quickstarts apply
cd /tmp/jboss-eap-quickstarts/remote-helloworld-mdb/
mvn clean package wildfly:deploy -Dcheckstyle.skip

```
curl http://localhost:8080/remote-helloworld-mdb/HelloWorldMDBServletClient
curl http://localhost:8080/remote-helloworld-mdb/HelloWorldMDBServletClient?topic
```
