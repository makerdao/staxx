APP_NAME ?= testchain_backendgateway
APP_VSN ?= 0.1.0
BUILD ?= `git rev-parse --short HEAD`
ALPINE_VERSION ?= 3.8
DOCKER_ID_USER ?= makerdao
MIX_ENV ?= prod

help:
	@echo "$(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

lint:
	@mix dialyzer --format dialyxir --quiet
	@mix credo
.PHONY: lint

deps: ## Load all required deps for project
	@mix do deps.get, deps.compile
.PHONY: deps

build: ## Build elixir application with testchain and WS API
	@docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(APP_NAME) \
    --build-arg APP_VSN=$(APP_VSN) \
    --build-arg MIX_ENV=$(MIX_ENV) \
    -t $(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD) \
    -t $(DOCKER_ID_USER)/$(APP_NAME):latest .
.PHONY: build

run: ## Run the app in Docker
	@docker run \
		-v /tmp/chains:/opt/chains \
		-v /tmp/snapshots:/opt/snapshots \
		--expose 4000 -p 4000:4000 \
		--expose 9100-9105 -p 9100-9105:9100-9105 \
		--rm -it $(DOCKER_ID_USER)/$(APP_NAME):latest
.PHONY: run

dev: ## Run local node with correct values
	@iex --name testchain_backendgateway@127.0.0.1 -S mix phx.server
.PHONY: dev

dc-up:
	@echo "+ $@"
	@docker-compose up -d
.PHONY: dc-up

dc-down:
	@echo "+ $@"
	@docker-compose down -v
.PHONY: dc-down
