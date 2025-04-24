# Configure Test EAP application as a client to AMQ

## Run AMQ

See the infra/amq-broker project to start a new broker.

Note 1: there is a bug in EAP that prefixes AMQ queues with jms.queue and jms.topic, even when the pooled connection factory has enable-amq1-prefix=false.  In particular, this happens with the use of the servlet in the teMDB test project.

Note 2: the AMQ broker in infra/amq-broker the following queues defined: HELLOWORLDMDBQueue, HELLOWORLDMDBTopic.

## Run EAP
```
export EAP_HOME=/redhat/eap/jboss-eap-7.4
$EAP_HOME/bin/standalone.sh -c standalone-full.xml -b 127.0.0.1
```


## Configure Remote Connection
```
export EAP_HOME=/redhat/eap/jboss-eap-7.4
$EAP_HOME/bin/jboss-cli.sh --connect --file=cli/7/configure.cli
```


## Create MDB and test

```
git clone -b 7.4.x --single-branch https://github.com/jboss-developer/jboss-eap-quickstarts.git /tmp/jboss-eap-quickstarts
cat patch/jboss-eap-7.4.patch | git -C /tmp/jboss-eap-quickstarts apply 
cd /tmp/jboss-eap-quickstarts/helloworld-mdb
mvn clean package wildfly:deploy -Dcheckstyle.skip

```
curl http://localhost:8080/helloworld-mdb/HelloWorldMDBServletClient
curl http://localhost:8080/helloworld-mdb/HelloWorldMDBServletClient?topic
```
