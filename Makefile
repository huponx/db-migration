COMPOSE ?= docker compose
DB_USER ?= postgres
DB_NAME ?= app

.PHONY: help up down restart logs ps build migrate info validate clean psql redis-cli

help:
	@printf '%s\n' \
		'up         start postgres + redis, then run the Flyway migrations' \
		'down       stop the containers (data kept)' \
		'restart    down + up' \
		'build      rebuild the flyway image (after changing the Dockerfile)' \
		'migrate    run the pending migrations again (after adding a V*.sql)' \
		'info       flyway info: applied and pending migrations' \
		'validate   flyway validate: checksums of the applied migrations' \
		'psql       psql shell in the database' \
		'redis-cli  redis-cli shell' \
		'logs       follow the logs' \
		'ps         list the containers' \
		'clean      stop and DELETE the volumes (fresh database)'

up:
	$(COMPOSE) up -d --build --wait postgres redis
	$(COMPOSE) run --rm --build flyway migrate

down:
	$(COMPOSE) down

restart: down up

build:
	$(COMPOSE) build flyway

migrate:
	$(COMPOSE) run --rm --build flyway migrate

info:
	$(COMPOSE) run --rm flyway info

validate:
	$(COMPOSE) run --rm flyway validate

psql:
	$(COMPOSE) exec postgres psql -U $(DB_USER) -d $(DB_NAME)

redis-cli:
	$(COMPOSE) exec redis redis-cli

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down -v
