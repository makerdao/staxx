EVM_NAME ?= ex_evm
EVM_VSN ?= v6.2.4
APP_NAME ?= staxx
APP_VSN ?= 0.1.0
BUILD ?= `git rev-parse --short HEAD`
ALPINE_VERSION ?= 3.9
DOCKER_ID_USER ?= makerdao
MIX_ENV ?= prod
TAG ?= latest

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
	@echo "Fixing chmod for EVM executables"
	@chmod +x priv/presets/ganache/wrapper.sh
	@chmod +x priv/presets/geth/geth_vdb
	@echo "Setting up ganache"
	@rm -rf priv/presets/ganache-cli
	@git clone --branch v6.6.0 https://github.com/trufflesuite/ganache-cli.git priv/presets/ganache-cli
	@cd priv/presets/ganache-cli && npm install --no-package-lock
	@echo "Setting up ganache finished !"
.PHONY: deps

docker-push:
	@echo "Pushing docker image"
	@docker push $(DOCKER_ID_USER)/$(APP_NAME):$(TAG)
.PHONY: docker-push

build-evm: ## Build the Docker image for geth/ganache/other evm
	@docker build -f ./Dockerfile.evm \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		-t $(DOCKER_ID_USER)/$(EVM_NAME):$(EVM_VSN)-$(BUILD) \
		-t $(DOCKER_ID_USER)/$(EVM_NAME):$(TAG) .

.PHONY: build-evm

build: ## Build elixir application with testchain and WS API
	@docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(APP_NAME) \
    --build-arg APP_VSN=$(APP_VSN) \
    --build-arg MIX_ENV=$(MIX_ENV) \
    -t $(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD) \
    -t $(DOCKER_ID_USER)/$(APP_NAME):$(TAG) .
.PHONY: build

upgrade-dev:
	@echo "====== Stopping and removing running containers"
	@docker-compose -f docker-compose-dev.yml rm -s -f
	@echo "====== Removing local images"
	@docker rmi -f makerdao/testchain-deployment:dev \
								 makerdao/ex_testchain:dev \
								 makerdao/$(APP_NAME):dev \
								 makerdao/testchain-dashboard
.PHONY: upgrade-dev

rm-dev:
	@echo "====== Stopping and removing running containers"
	@docker-compose -f docker-compose-dev.yml rm -s -f
.PHONY: rm-dev

logs-deploy:
	@docker-compose logs -f testchain-deployment
.PHONY: logs-deploy

logs-dev:
	@docker-compose logs -f ex_testchain $(APP_NAME) testchain-deployment
.PHONY: logs-dev

run: ## Run the app in Docker
	@docker run \
		-v /tmp/chains:/opt/chains \
		-v /tmp/snapshots:/opt/snapshots \
		-v /tmp/stacks:/opt/stacks \
		--expose 4000 -p 4000:4000 \
		--expose 9100-9105 -p 9100-9105:9100-9105 \
		--rm -it $(DOCKER_ID_USER)/$(APP_NAME):latest
.PHONY: run

run-dev:
	@docker-compose -f ./docker-compose-dev.yml up -d
.PHONY: run-dev

run-elixir-env:
	@docker-compose -f ./docker-compose-elixir.yml up -d
.PHONY: run-elixir-env

stop-dev:
	@docker-compose -f ./docker-compose-dev.yml stop
.PHONY: stop-dev

dev: ## Run local node with correct values
	@iex --name $(APP_NAME)@127.0.0.1 -S mix phx.server
.PHONY: dev

dc-up:
	@echo "+ $@"
	@docker-compose up -d
.PHONY: dc-up

dc-down:
	@echo "+ $@"
	@docker-compose down -v
.PHONY: dc-down

run-latest:
	@docker-compose -f ./docker-compose.yaml up -d
.PHONY: run-latest

stop-latest:
	@docker-compose -f ./docker-compose.yaml stop
.PHONY: stop-latest

rm-latest:
	@echo "====== Stopping and removing running containers"
	@docker-compose -f docker-compose.yaml rm -s -f
.PHONY: rm-latest
