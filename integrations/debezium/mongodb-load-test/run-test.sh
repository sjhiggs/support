#!/bin/bash

# try to add the connector if it doesn't already exist
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @my.json

# run the load test on the mongo pod
podman cp load_test.js mongo1:load_test.js 
podman exec -i mongo1 mongosh "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0" --file load_test.js
