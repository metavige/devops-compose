#!/bin/bash

DOT_ENV="${PWD}/.env"
source $DOT_ENV
COMPOSE_FILE="$1/docker-compose.yml"

if [ -d $1 ]
then
  docker compose --env-file=$DOT_ENV \
    -f $BASE_NETWORK_YAML \
    -f $COMPOSE_FILE config
else
  echo "$1 not existed!"
fi