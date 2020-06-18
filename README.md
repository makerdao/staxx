# STAXX
[![Build Status](https://travis-ci.org/makerdao/staxx.svg?branch=master)](https://travis-ci.org/makerdao/staxx)
[![CircleCI](https://circleci.com/gh/makerdao/staxx.svg?style=svg)](https://circleci.com/gh/makerdao/staxx)


## Prerequisite Installations
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
  - The docker compose service manages all the docker images needed for the setup and use of the testchain environment.


## Naming convention

 - `Staxx` - Main project name.
 - `Environment` - Your testing environment containing `Testchain` and other `Extensions`.
 - `Testchain` - Ethereum Virtual Machine (EVM) that will be seted up for your `Environment`.
 - `Extension` - Plugin (set of docker images) provides additional functionality and running near `Testchain`, controlled by your `Environment`.

## Installation

Before starting, you should confirm that you have docker compose up and running.
For **MacOS** and **Windows**: you can check this by looking in the top right side of your computer screen, and selecting the whale icon for more details about running docker.
For **Linux** follow this: https://docs.docker.com/install/

## Getting Started

1. Open a fresh new terminal window
2. `git clone git@github.com:makerdao/staxx.git`
3. `cd staxx`
    1. Check to make sure it is up to date by running `git pull`


**Note to help mitigate issues early testers may run into when getting the testchain running:**

1. Run `make docker-deps` to download list of required images (EVM docker images will be downloaded).
2. Run `docker images` (make sure you see `staxx` present)
3. In the case that you have used docker in the past for other projects and your images are scattered, you may want to refresh the service.
    1. To do so, run `make upgrade-dev` (Command will stop running containers, remove them and remove old docker images)


Next, the following command ensures you do not have any lingering chains left over from a past deployment  - `make clear-dev` (This step **only** applies to developers who have run the testchain environment before).

## Getting the testchain up and running:
4. Add this lines to your `/etc/hosts` file (you might need to use `sudo` to edit file): 

```txt
127.0.0.1 nats.local
127.0.0.1 db.local
127.0.0.1 staxx.local
```

5. Run `make migrate-dev` to setup required DB tables.

Migrations should look like:
```bash
➜  staxx develop ✗ make migrate-dev
Creating db.local ... done
Starting db.local ... done
Creating nats.local ... done
09:26:16.478 [info] == Running 20191119092033 Staxx.Store.Repo.Migrations.Users.change/0 forward
09:26:16.479 [info] create table users
09:26:16.510 [info] create index users_email_index
09:26:16.517 [info] == Migrated 20191119092033 in 0.0s
09:26:16.548 [info] == Running 20191119092055 Staxx.Store.Repo.Migrations.Chain.change/0 forward
09:26:16.549 [info] create table chains
09:26:16.571 [info] create index chains_id_index
09:26:16.576 [info] create index chains_node_type_index
09:26:16.581 [info] == Migrated 20191119092055 in 0.0s
09:26:16.585 [info] == Running 20191119092758 Staxx.Store.Repo.Migrations.ChainEvents.change/0 forward
09:26:16.586 [info] create table chain_events
09:26:16.602 [info] create index chain_events_chain_id_event_index
09:26:16.607 [info] == Migrated 20191119092758 in 0.0s
09:26:16.610 [info] == Running 20200109091056 Staxx.Store.Repo.Migrations.CreateSnapshotsTable.change/0 forward
09:26:16.611 [info] create table snapshots
09:26:16.624 [info] create index snapshots_id_index
09:26:16.629 [info] == Migrated 20200109091056 in 0.0s
```

It means everything is ok. 

6. Next, we will pull everything from the docker container and will be ready to get the testchain up and running:
    1. Run `make run-dev`
        1. This step pulls all the images from docker down and will start the QA portal in docker images and then will set `localhost:4001` - for UI and `localhost:4000` - for WS/Web API.
        2. You will see that it will immediately start pulling from the staxx.
        3. You can also check Staxx by using `make ping-dev` command.

7. Once everything has been pulled down, the next step is to check the logs:
    1. Run `make logs-dev`
        1. This command will display all the logs from testchain network.
        2. When running this, you want to keep an eye out for the first code block to confirm. This will confirm that it is indeed working for you.


The first block will appear in your terminal window as follows:

```
staxx.local             | 09:27:27.396 [debug] Connected to Nats.io with config %{host: "nats.local", port: 4222}
staxx.local             | 09:27:27.396 [debug] Subscribed to EventBus topics
staxx.local             | 09:27:27.397 [debug] Starting Port Mapper
staxx.local             | 09:27:27.397 [debug] New docker events spawned with port #Port<0.14>
staxx.local             | 09:27:27.447 [debug] Elixir.Staxx.DeploymentScope.Terminator: Come with me if you want to live...
staxx.local             | 09:27:27.450 [debug] Elixir.Staxx.DeploymentScope.Stack.ConfigLoader: Loaded list of staks configs
staxx.local             | %{}
staxx.local             |
staxx.local             | 09:27:27.454 [debug] Starting Prometheus endpoint on port 9568, route: /metrics
staxx.local             | 09:27:27.468 [info] Running Staxx.WebApiWeb.Endpoint with cowboy 2.7.0 at :::4000 (http)
staxx.local             | 09:27:27.468 [info] Access Staxx.WebApiWeb.Endpoint at http://localhost:4000
```

Your testchain is now up and running! You are now able to start using services, such as interacting with the [testchain dashboard](https://github.com/makerdao/testchain-dashboard) or using raw API.

## Docker Compose

Docker-compose script supports several `ENV`:
 - `dev` - Mostly used on your local machine. All latest changes and cool features included.
 - `latest` - Most stable but almost always a little bit outdated version. For production use.
 - `test` - Made for testing source code, probably nobody will use it. 

You can use any of this `ENV` in your commands, just replace `${ENV}` to required one.
Example: `make migrate-dev && make run-dev`

#### Usage: 

1. Build or download all required images `make docker-deps`.
2. Use `make migrate-${ENV}` to setup DB schema for app.
3. Use `make run-${ENV}` to run.
4. Use `make stop-${ENV}` to stop containers.
5. Use `make rm-${ENV}` to remove containers (except PostgreSQL data `./docker/postgres-data`).

Instead of doing steps 2 and 3, you can run the `docker-compose` command in your console.
NOTE: You will have to use `docker-compose -f ./docker/docker-compose.yaml` to point compose to correct file.


## Pulling docker EVM container (Etherial Virtual Machine)

For now only `geth|ganache` supported.
Run `make pull-evms` and system will download latest versions for EVM docker images.

## Full List of Testchain Commands (Docker Compose):

- `make migrate-dev`
    - This command will start DB container and sill apply list of migrations to PostgreSQL.
- `make run-dev`
    - This command will start the QA portal in docker images and will then set it to  `localhost:4001` for the UI view and `localhost:4000` for the WS/Web API.
- `make logs-dev`
    - This command will display all of the logs from system.
- `make logs-deploy`
    - This command will display a list of logs for deployment service/everything you will need to get it up and running.
- `make stop-dev`
    - This command stops all services.
- `make rm-dev`
    - This command will remove local containers (not the images, only the containers)
- `make upgrade-dev`
    - This command will stop all of the running containers and remove them as well as images.

## Setting up Extensions

**Defining a Extension:** a Extension is a collection of backend services brought together for a specific purpose.


### Extension Manager Services:
- VulcanizeDB Extension
- Price Oracles Extension
- Keepers

**What is a `Extension Manager Service`?**

In short, the extension manager service is essentially a plugin interface for your the specific extension you want to work with.

For example, the Testchain Vulcanize DB extension manager service will handle list of events from testchain.

For now we support only `vdb` extension available
[Github VDB repo](https://github.com/makerdao/testchain-stack-vdb)

**Example:** Testchain Vulcanize DB Extension Manager Service

**Note:** If you are using `docker-compose` for starting QA Dashboard from https://github.com/makerdao/staxx, you will have to put the 3 above files from extension_config into the `/tmp/extensions/vdb` folder on your local machine before starting the local environment.The following three files will be:

1. Docker-compose.yml
2. Icon.png
3. Extension.json
