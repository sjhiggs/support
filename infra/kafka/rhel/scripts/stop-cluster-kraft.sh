#!/bin/bash

pkill -f "server-0.properties"
pkill -f "server-1.properties"
pkill -f "server-2.properties"

pkill -f "controller-0.properties"
pkill -f "controller-1.properties"
pkill -f "controller-2.properties"

pkill -f "server-3.properties"
pkill -f "server-4.properties"
pkill -f "server-5.properties"

pkill -f "broker-3.properties" --signal SIGKILL
pkill -f "broker-4.properties" --signal SIGKILL
pkill -f "broker-5.properties" --signal SIGKILL

