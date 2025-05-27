#!/bin/bash

trap "echo Exiting...; exit 0" SIGINT

while true; do
  curl "http://localhost:8080/route/health"
  sleep 1 # Optional: pause between requests
done
