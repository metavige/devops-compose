#!/bin/bash

TARGET_DIR=$1
DOT_ENV="${PWD}/.env"
source $DOT_ENV
COMPOSE_FILE="$TARGET_DIR/docker-compose.yml"

shift 1

if [ -d $TARGET_DIR ]
then
  docker compose --project-directory=$TARGET_DIR \
    --env-file=$DOT_ENV \
    -f $BASE_NETWORK_YAML \
    -f $COMPOSE_FILE $@

else
  echo "$TARGET_DIR not existed!"
fi