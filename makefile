include .env

DOT_ENV=${PWD}/.env
TARGET_DIR=${service}
COMPOSE_FILE="${service}/docker-compose.yml"
COMPOSE_ARGS=--project-directory=${TARGET_DIR} \
    --env-file=${DOT_ENV} \
    -f ${BASE_NETWORK_YAML} \
    -f ${COMPOSE_FILE}

.PHONY: start stop config
start:
	docker compose ${COMPOSE_ARGS} up -d

restart:
	docker compose ${COMPOSE_ARGS} restart

stop:
	docker compose ${COMPOSE_ARGS} stop

config:
	docker compose ${COMPOSE_ARGS} config