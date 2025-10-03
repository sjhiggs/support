#!/bin/bash

#
# Example Usage
# 

readonly USAGE="
Usage: kafka-get.sh [options]

Required:
  --kafka-version=<string>		the upstream kafka version to use for the client
  

"
OPTSPEC=":-:"
while getopts "$OPTSPEC" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        kafka-version=*)
          KAFKA_VERSION=${OPTARG#*=}
          ;;
        *)
          error "$USAGE"
          ;;
      esac;;
  esac
done

error() {
  echo "$@" 1>&2 && exit 1
}

shift $((OPTIND-1))

echo "kafka version:  $KAFKA_VERSION"

if [[ -z $KAFKA_VERSION ]]; then
  error "$USAGE"
fi

echo "start of script..."

# from https://github.com/fvaleri/strimzi-debugging/blob/main/init.sh
for x in curl xz java; do
  if ! command -v "$x" &>/dev/null; then
    echo "Missing required utility: $x"; exit 1
  fi
done

# get Kafka
KAFKA_HOME="/tmp/kafka-$KAFKA_VERSION" && export KAFKA_HOME
if [[ ! -d $KAFKA_HOME ]]; then
  echo "Downloading Kafka to $KAFKA_HOME"
  mkdir -p "$KAFKA_HOME"
  curl -sLk "https://dlcdn.apache.org/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz" | tar xz -C "$KAFKA_HOME" --strip-components 1
#https://dlcdn.apache.org/kafka/3.9.1/kafka_2.13-3.9.1.tgz
fi


echo "end of script"
