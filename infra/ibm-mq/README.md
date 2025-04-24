# Install local podman IBM-MQ instance

## Details

* Queue manager QM1
* Queue DEV.QUEUE.1
* Channel: DEV.APP.SVRCONN
* Listener: SYSTEM.LISTENER.TCP.1 on port 1414
* Username: app
* Password: foobar


## Create podman container

```
podman pull icr.io/ibm-messaging/mq:latest
podman volume create qm1data
podman run --env LICENSE=accept --env MQ_QMGR_NAME=QM1 --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --env MQ_APP_PASSWORD=foobar --name QM1 icr.io/ibm-messaging/mq:latest
```

## Test local IBM MQ instance with camel route

Requires jbang with camel
Tested with Java 21 (uses jakarta package name). Run the route:

```
$ camel run camel-mq-client/MQRoute.java
```

# Add custom queues to MQ podman image

TODO: not working!

```
podman build -t myibmmq custom-mq/.
podman run --env LICENSE=accept --env MQ_QMGR_NAME=QM1 --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --env MQ_APP_PASSWORD=foobar --name QM1 localhost/myibmmq:latest
```

need permissions?  something like the following fomrat:

setmqaut -m QM.MQT2 -t queue -n NY.TD.INPUT -g TESTGROUP +get +put
