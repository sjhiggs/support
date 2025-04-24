#!/bin/bash

cd "$(dirname "$0")"

cp env.bak env
source ./env

mkdir -p "$data_dir"
mkdir "$data_dir/$ca_dir"
mkdir "$data_dir/$ca_issuing_dir"
mkdir "$data_dir/$certs_dir"
