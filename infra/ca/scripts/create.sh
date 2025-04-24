#!/bin/bash

cd "$(dirname "$0")"
echo $PWD
source ./env

./clean.sh
./init.sh
./ca.sh
./ca-issuing.sh
