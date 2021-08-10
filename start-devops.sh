#!/bin/bash

DOT_ENV="${PWD}/.env"
COMPOSE_FILE="$1/docker-compose.yml"

if [ -d $1 ]
then
  docker compose --env-file=$DOT_ENV -f $COMPOSE_FILE up -d
else
  echo "$1 not existed!"
fi