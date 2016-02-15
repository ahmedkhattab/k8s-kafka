#!/bin/bash

function getKey() {
  echo $1 | cut -d "=" -f1
}

function getValue() {
  echo $1 | cut -d "=" -f2
}

function envValue() {
 local entry=`env | grep $1`
 echo `getValue $entry`
}

set -ex

#Find the server id
SERVER_ID=$(hostname -I | sed -r 's/(.[^ ]+).*/\1/g;s/\.//g')
if [ ! -z "$SERVER_ID" ] ; then
  export ADVERTISED_HOST_NAME=$(hostname -I)
  export ADVERTISED_PORT=`envValue KAFKA_ADVERTISED_PORT`

  # Find the zookeepers exposed in env.
  ZOOKEEPER_CONNECT=""
  for i in `echo {1..15}`; do
    ZK_CLIENT_HOST=`envValue ZOOKEEPER_${i}_SERVICE_HOST`
    ZK_CLIENT_PORT=`envValue ZOOKEEPER_${i}_SERVICE_PORT_CLIENT`

    if [ -z "$ZK_CLIENT_HOST" ] || [ -z "$ZK_CLIENT_PORT" ] ; then
      break
    else
      if [ ! -z $ZOOKEEPER_CONNECT ] ; then
        ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT},"
      fi
      ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT}${ZK_CLIENT_HOST}:${ZK_CLIENT_PORT}"
    fi
  done
fi

# Build the server configuration
 sed -i "s|{{BROKER_ID}}|${SERVER_ID}|g" /kafka/config/server.properties
 sed -i "s|{{ADVERTISED_HOST_NAME}}|${HOSTNAME}|g" /kafka/config/server.properties
 sed -i "s|{{ADVERTISED_PORT}}|${ADVERTISED_PORT}|g" /kafka/config/server.properties
 sed -i "s|{{ZOOKEEPER_CONNECT}}|${ZOOKEEPER_CONNECT}|g" /kafka/config/server.properties

export CLASSPATH=$CLASSPATH:/kafka/lib/slf4j-log4j12.jar
export JMX_PORT=7203

echo "Starting kafka"

exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
