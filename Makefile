EVM_NAME ?= ex_evm
EVM_VSN ?= v6.2.4
EX_TESTCHAIN_APP_NAME ?= ex_testchain
EX_TESTCHAIN_APP_VSN ?= 0.1.0
APP_NAME ?= staxx
APP_VSN ?= 0.1.0
BUILD ?= `git rev-parse --short HEAD`
ALPINE_VERSION ?= 3.9
DOCKER_ID_USER ?= makerdao
MIX_ENV ?= prod
TAG ?= latest
DEPLOYMENT_WORKER_IMAGE ?= "makerdao/testchain-deployment-worker:$(TAG)"
GETH_TAG ?= v1.8.27
GETH_VDB_TAG ?= v1.10-alpha.0

help:
	@echo "$(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

lint:
	@mix dialyzer --format dialyxir --quiet
	@mix credo
.PHONY: lint

clean-local:
	@rm -rf /tmp/chains/*
.PHONY: clean-local

docker-deps:
	@docker pull $(DEPLOYMENT_WORKER_IMAGE)
.PHONY: docker-deps

deps: ## Load all required deps for project
	@mix do deps.get, deps.compile
	@echo "Fixing chmod for EVM executables"
	@chmod +x priv/presets/ganache/wrapper.sh
	@chmod +x priv/presets/geth/geth_vdb
.PHONY: deps

ganache-fetch:
	@echo "Setting up ganache"
	@rm -rf priv/presets/ganache-cli
	@git clone --branch v6.6.0 https://github.com/trufflesuite/ganache-cli.git priv/presets/ganache-cli
.PHONY: ganache-fetch

ganache-local:
	@echo "Setting up ganache"
	@rm -rf priv/presets/ganache-cli
	@git clone --branch v6.6.0 https://github.com/trufflesuite/ganache-cli.git priv/presets/ganache-cli
	@cd priv/presets/ganache-cli && npm install --no-package-lock
	@echo "Setting up ganache finished !"
.PHONY: ganache-local

geth-local:
	@echo "Setting up geth"
	@rm -rf priv/presets/geth_local
	@rm -f priv/presets/geth/geth
	@git clone --single-branch --branch $(GETH_TAG) https://github.com/ethereum/go-ethereum.git priv/presets/geth_local
	@cd priv/presets/geth_local && \
		sed -i -e 's/GasLimit:   6283185,/GasLimit:   0xffffffffffffffff,/g' core/genesis.go && \
		sed -i -e 's/MaxCodeSize = 24576/MaxCodeSize = 1000000/g' params/protocol_params.go && \
		sed -i -e 's/return ErrOversizedData//g' core/tx_pool.go && \
		make geth && \
		mv build/bin/geth ../geth/
	@rm -rf priv/presets/geth_local
	@echo "Setting up geth finished 'priv/presets/geth/geth' !"
.PHONY: geth-local

geth-vdb-local:
	@echo "Setting up geth_vdb"
	@rm -rf priv/presets/geth_vdb_local
	@rm -f priv/presets/geth/geth_vdb
	@git clone --single-branch --branch $(GETH_VDB_TAG) https://github.com/vulcanize/go-ethereum.git priv/presets/geth_vdb_local
	@cd priv/presets/geth_vdb_local && \
		sed -i -e 's/GasLimit:   6283185,/GasLimit:   0xffffffffffffffff,/g' core/genesis.go && \
		sed -i -e 's/MaxCodeSize = 24576/MaxCodeSize = 1000000/g' params/protocol_params.go && \
		sed -i -e 's/return ErrOversizedData//g' core/tx_pool.go && \
		make geth && \
		mv build/bin/geth ../geth/geth_vdb
	@rm -rf priv/presets/geth_vdb_local
	@echo "Setting up geth finished 'priv/presets/geth/geth_vdb' !"
.PHONY: geth-vdb-local

evm-local: ganache-local geth-local geth-vdb-local
	@echo "Built all EVMs"
.PHONY: geth-vdb-local

docker-push:
	@echo "Pushing Staxx docker image"
	@docker push $(DOCKER_ID_USER)/$(APP_NAME):$(TAG)
	@echo "Pushing ex_evm & ex_testchain docker image"
	@docker push $(DOCKER_ID_USER)/$(EVM_NAME):$(TAG)
	@docker push $(DOCKER_ID_USER)/$(EX_TESTCHAIN_APP_NAME):$(TAG)
.PHONY: docker-push

build-evm: ## Build the Docker image for geth/ganache/other evm
	@docker build -f ./Dockerfile.evm \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg GETH_TAG=$(GETH_TAG)
		-t $(DOCKER_ID_USER)/$(EVM_NAME):$(EVM_VSN)-$(BUILD) \
		-t $(DOCKER_ID_USER)/$(EVM_NAME):$(TAG) .

.PHONY: build-evm

build-chain: ## Build elixir application with testchain and WS API
	@docker build -f ./Dockerfile.ex_chain \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(EX_TESTCHAIN_APP_NAME) \
		--build-arg APP_VSN=$(EX_TESTCHAIN_APP_VSN) \
		--build-arg EVM_IMAGE=$(DOCKER_ID_USER)/$(EVM_NAME):$(TAG) \
		-t $(DOCKER_ID_USER)/$(EX_TESTCHAIN_APP_NAME):$(EX_TESTCHAIN_APP_VSN)-$(BUILD) \
		-t $(DOCKER_ID_USER)/$(EX_TESTCHAIN_APP_NAME):$(TAG) .
.PHONY: build-chain

build: ## Build elixir application with testchain and WS API
	@docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg DEPLOYMENT_WORKER_IMAGE=$(DEPLOYMENT_WORKER_IMAGE) \
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

staxx-remote:
	@docker run -it --rm --network staxx_net1 makerdao/staxx:dev ./bin/staxx remote
.PHONY: staxx-remote

staxx-bash:
	@docker run -it --rm --network staxx_net1 makerdao/staxx:dev /bin/bash
.PHONY: staxx-bash

ex-testchain-remote:
	@docker run -it --rm --network staxx_net1 makerdao/ex_testchain:dev ./bin/staxx remote
.PHONY: ex-testchain-remote

ex-testchain-bash:
	@docker run -it --rm --network staxx_net1 makerdao/ex_testchain:dev /bin/bash
.PHONY: ex-testchain-bash