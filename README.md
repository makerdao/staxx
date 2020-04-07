# STAXX
[![Build Status](https://travis-ci.org/makerdao/staxx.svg?branch=master)](https://travis-ci.org/makerdao/staxx)
[![CircleCI](https://circleci.com/gh/makerdao/staxx.svg?style=svg)](https://circleci.com/gh/makerdao/staxx)


## Prerequisite Installations
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
  - The docker compose service manages all the docker images needed for the setup and use of the testchain environment.


## Docker Compose

1. Build all images.
2. Use `make migrate` to setup DB schema for app.
3. Use `make run-latest` to run.
4. Use `make stop-latest` to stop containers.
5. Use `make rm-latest` to remove containers (except PostgreSQL data `./docker/postgres-data`).

Instead of doing steps 2 and 3, you can run the `docker-compose` command in your console.
NOTE: You will have to use `docker-compose -f ./docker/docker-compose.yaml` to point compose to correct file.

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

## Pulling docker EVM container (Etherial Virtual Machine)

For now only `geth|ganache` supported.
Run `make pull-evms` and system will download latest versions for EVM docker images.

## Getting the testchain up and running:


4. Next, we will pull everything from the docker container and will be ready to get the testchain up and running:
    1. Run `make run-dev`
        1. This step pulls all the images from docker down and will start the QA portal in docker images and then will set `localhost:4001` - for UI and `localhost:4000` - for WS/Web API.
        2. You will see that it will immediately start pulling from the staxx.

5. Once everything has been pulled down, the next step is to check the logs:
    1. Run `make logs-dev`
        1. This command will display all the logs from testchain network.
        2. When running this, you want to keep an eye out for the first code block to confirm. This will confirm that it is indeed working for you.


The first block will appear in your terminal window as follows:

```

TODO: udpate deployment started logs

```

After the appearance of the first code block, you will have to wait between 1-15 minutes before it has fully booted.

Once the testchain has fully booted, you will see similar output as displayed below (this will constantly update as you interact with testchain services):

```

TODO: Update deployment success logs

```

Your testchain is now up and running! You are now able to start using services, such as interacting with the [testchain dashboard](https://github.com/makerdao/testchain-dashboard).


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

## Setting up Stacks

**Defining a Stack:** a Stack is a collection of backend services brought together for a specific purpose.


### Stack Manager Services:
- VulcanizeDB Stack
- Price Oracles Stack
- Keepers

**What is a `Stack Manager Service`?**

In short, the stack manager service is essentially a plugin interface for your the specific stack you want to work with.

For example, the Testchain Vulcanize DB stack manager service will handle list of events from testchain.

For now we support only `vdb` stack available
[Github VDB repo](https://github.com/makerdao/testchain-stack-vdb)

**Example:** Testchain Vulcanize DB Stack Manager Service

**Note:** If you are using `docker-compose` for starting QA Dashboard from https://github.com/makerdao/staxx, you will have to put the 3 above files from stack_config into the `/tmp/stacks/vdb` folder on your local machine before starting the local environment.The following three files will be:

1. Docker-compose.yml
2. Icon.png
3. Stack.json
