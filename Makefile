APP_NAME ?= staxx
APP_VSN ?= 0.1.0
BUILD ?= `git rev-parse --short HEAD`
ALPINE_VERSION ?= 3.9
DOCKER_ID_USER ?= makerdao
MIX_ENV ?= prod
TAG ?= latest
DEPLOYMENT_WORKER_IMAGE ?= "makerdao/testchain-deployment-worker:$(TAG)"
GETH_IMAGE ?= geth_evm
GETH_TAG ?= 1.8.27
GANACHE_IMAGE ?= ganache_evm
GANACHE_TAG ?= 6.7.0
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

pull-evms:
	@docker pull $(DOCKER_ID_USER)/$(GANACHE_IMAGE):$(GANACHE_TAG)
	@docker pull $(DOCKER_ID_USER)/$(GETH_IMAGE):$(GETH_TAG)
.PHONY: pull-evms

docker-deps: pull-evms
	@docker pull $(DEPLOYMENT_WORKER_IMAGE)
.PHONY: docker-deps

deps: docker-deps
	@mix deps.get
.PHONY: deps

ganache-local:
	@echo "Setting up ganache"
	@rm -rf priv/presets/ganache-cli
	@git clone --branch v6.6.0 https://github.com/trufflesuite/ganache-cli.git priv/presets/ganache-cli
	@cd priv/presets/ganache-cli && npm install --no-package-lock
	@echo "Setting up ganache finished !"
.PHONY: ganache-local

ganache-docker-image:
	@echo "Building ganache docker image"
	@docker build -f docker/evm/Dockerfile.ganache -t $(DOCKER_ID_USER)/$(GANACHE_IMAGE):$(GANACHE_TAG) .
.PHONY: ganache-docker-image

geth-docker-image:
	@echo "Building geth docker image"
	@docker build -f docker/evm/Dockerfile.geth -t $(DOCKER_ID_USER)/$(GETH_IMAGE):$(GETH_TAG) .
.PHONY: geth-docker-image

geth-local:
	@echo "Setting up geth"
	@rm -rf priv/presets/geth_local
	@rm -f priv/presets/geth/geth
	@git clone --single-branch --branch v$(GETH_TAG) https://github.com/ethereum/go-ethereum.git priv/presets/geth_local
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

docker-push-evm:
	@echo "Pushing evm docker iamges"
	@docker push $(DOCKER_ID_USER)/$(GANACHE_IMAGE):$(GANACHE_TAG)
	@docker push $(DOCKER_ID_USER)/$(GETH_IMAGE):$(GETH_TAG)
.PHONY: docker-push-evm

docker-push: docker-push-evm
	@echo "Pushing Staxx docker image"
	@docker push $(DOCKER_ID_USER)/$(APP_NAME):$(TAG)
.PHONY: docker-push

build: ## Build elixir application with testchain and WS API
	@docker build -f ./docker/Dockerfile \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg APP_NAME=$(APP_NAME) \
		--build-arg APP_VSN=$(APP_VSN) \
		--build-arg DEPLOYMENT_WORKER_IMAGE=$(DEPLOYMENT_WORKER_IMAGE) \
		--build-arg MIX_ENV=$(MIX_ENV) \
		-t $(DOCKER_ID_USER)/$(APP_NAME):$(APP_VSN)-$(BUILD) \
		-t $(DOCKER_ID_USER)/$(APP_NAME):$(TAG) .
.PHONY: build

logs-deploy:
	@docker-compose -f ./docker/docker-compose-dev.yml logs -f testchain-deployment
.PHONY: logs-deploy

logs-dev:
	@docker-compose -f ./docker/docker-compose-dev.yml logs -f $(APP_NAME)
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

migrate-latest:
	@docker-compose -f docker/docker-compose.yml run --rm staxx eval "Staxx.Store.Release.migrate()"
.PHONY: migrate-latest

run-latest:
	@docker-compose -f ./docker/docker-compose.yaml up -d
.PHONY: run-latest

stop-latest:
	@docker-compose -f ./docker/docker-compose.yaml stop
.PHONY: stop-latest

rm-latest:
	@echo "====== Stopping and removing running containers"
	@docker-compose -f docker/docker-compose.yaml rm -s -f
.PHONY: rm-latest

migrate-dev:
	@docker-compose -f docker/docker-compose-dev.yml run --rm staxx eval "Staxx.Store.Release.migrate()"
.PHONY: migrate-dev

run-dev:
	@docker-compose -f ./docker/docker-compose-dev.yml up -d
.PHONY: run-dev

stop-dev:
	@docker-compose -f ./docker/docker-compose-dev.yml stop
.PHONY: stop-dev

rm-dev: stop-dev
	@echo "====== Stopping and removing running containers"
	@docker-compose -f ./docker/docker-compose-dev.yml rm -s -f
.PHONY: rm-dev

upgrade-dev: rm-dev
	@echo "====== Removing local images"
	@docker rmi -f $(DOCKER_ID_USER)/testchain-deployment:dev \
					$(DEPLOYMENT_WORKER_IMAGE) \
					$(DOCKER_ID_USER)/$(APP_NAME):dev \
					$(DOCKER_ID_USER)/testchain-dashboard
.PHONY: upgrade-dev

clear-dev:
	@rm -rf /tmp/chains /tmp/snapshots ./docker/postgres-data
.PHONY: clear-dev

migrate-test:
	@docker-compose -f docker/docker-compose-test.yml run --rm staxx eval "Staxx.Store.Release.migrate()"
.PHONY: migrate-test

run-test:
	@docker-compose -f ./docker/docker-compose-test.yml up -d
.PHONY: run-test

stop-test:
	@docker-compose -f ./docker/docker-compose-test.yml stop
.PHONY: stop-test

rm-test: stop-test
	@echo "====== Stopping and removing running containers"
	@docker-compose -f ./docker/docker-compose-test.yml rm -s -f
.PHONY: rm-test

stop-elixir-env:
	@docker-compose -f ./docker/docker-compose-elixir.yml stop
.PHONY: stop-elixir-env

rm-elixir-env: stop-elixir-env
	@docker-compose -f ./docker/docker-compose-elixir.yml rm
.PHONY: rm-elixir-env

run-elixir-env: rm-elixir-env
	@docker-compose -f ./docker/docker-compose-elixir.yml up -d
.PHONY: run-elixir-env

dev: ## Run local node with correct values
	@iex --name $(APP_NAME)@127.0.0.1 -S mix phx.server
.PHONY: dev

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
