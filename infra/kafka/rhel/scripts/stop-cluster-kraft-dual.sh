#!/bin/bash

pkill -f "server-0.properties"
pkill -f "server-1.properties"
pkill -f "server-2.properties"

pkill -f "server-3.properties"
pkill -f "server-4.properties"
pkill -f "server-5.properties"


#eval rm -rf /tmp/kafka-{0..5}
