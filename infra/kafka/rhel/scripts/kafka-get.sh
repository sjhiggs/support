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

for x in curl tar java; do
  if ! command -v "$x" &>/dev/null; then
    echo "Missing required utility: $x"; exit 1
  fi
done

# get Kafka
KAFKA_HOME="/tmp/kafka-$KAFKA_VERSION" && export KAFKA_HOME
if [[ ! -d $KAFKA_HOME ]]; then
  CDN_URL="https://dlcdn.apache.org/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz"
  ARCHIVE_URL="https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz"

  echo "Downloading Kafka to $KAFKA_HOME"
  mkdir -p "$KAFKA_HOME"

  HTTP_CODE=$(curl -sL -o /dev/null -w "%{http_code}" "$CDN_URL")
  if [[ "$HTTP_CODE" == "200" ]]; then
    DOWNLOAD_URL="$CDN_URL"
  else
    echo "Not found on CDN, trying archive..."
    DOWNLOAD_URL="$ARCHIVE_URL"
  fi

  if ! curl -sLk "$DOWNLOAD_URL" | tar xz -C "$KAFKA_HOME" --strip-components 1; then
    rm -rf "$KAFKA_HOME"
    error "Failed to download Kafka $KAFKA_VERSION"
  fi
fi

echo "end of script"
