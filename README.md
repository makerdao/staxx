# TestchainBackend
[![Build Status](https://travis-ci.org/makerdao/testchain-backendgateway.svg?branch=master)](https://travis-ci.org/makerdao/testchain-backendgateway)


## Prerequisite Installations
- [Node](https://nodejs.org/en/download/) (Version >= 8.9.0) 
- [Yarn](https://yarnpkg.com/en/)
- [Docker Compose](https://docs.docker.com/compose/)
  - The docker compose service manages all the docker images needed for the setup and use of the testchain environment. 


## Docker Compose

1. Build all images.
2. Use `make dc-up` to run.
3. Use `make dc-down` to remove data.

Instead of doing steps 2 and 3, you can run the `docker-compose` command in your console.

## Installation

Before starting, you should confirm that you have docker compose up and running. You can check this by looking in the top right side of your computer screen, and selecting the whale icon for more details about running docker. 

## Getting Started

1. Open a fresh new terminal window 
2. `git clone git@github.com:makerdao/testchain-backendgateway.git`
3. `cd testchain-backendgateway`
    1. Check to make sure it is up to date by running `git pull`


**Note to help mitigate issues early testers may run into when getting the testchain running:** 

1. Run `docker images` (make sure you see `testchain_backendgateway` present)
2. In the case that you have used docker in the past for other projects and your images are scattered, you may want to refresh the service. 
    1. To do so, run `make upgrade-dev`
    2. `make rm-dev` (This commands checks if the containers have stopped)


Next, the following command ensures you do not have any lingering chains left over from a past deployment `rm -r /tmp/chains /tmp/snapshots`(This step only applies to developers who have run the testchain environment before).


## Getting the testchain up and running:


4. Next, we will pull everything from the docker container and will be ready to get the testchain up and running: 
    1. Run `make run-dev` 
        1. This step pulls all the images from docker down and will start the QA portal in docker images and then will set `localhost:4001` - for UI and `localhost:4000` - for WS/Web API.
        2. You will see that it will immediately start pulling from the testchain-backendgateway.
    
5. Once everything has been pulled down, the next step is to check the logs:
    1. Run `make logs-dev`
        1. This command will display all the logs from testchain network.
        2. When running this, you want to keep an eye out for the first code block to confirm. This will confirm that it is indeed working for you. 
        

The first block will appear in your terminal window as follows: 

```

master ✓ make logs-deploy
Attaching to testchain-deployment.local
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="Config loaded" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=debug msg="Config: &{Server:HTTP Host:testchain-deployment Port:5001 Deploy:{DeploymentDirPath:/deployment DeploymentSubPath:./ ResultSubPath:out/addresses.json} Gateway:{Host:testchain-backendgateway.local Port:4000 ClientTimeoutInSecond:5 RegisterPeriodInSec:10} Github:{RepoOwner:makerdao RepoName:testchain-dss-deployment-scripts DefaultCheckoutTarget:tags/qa-deploy} NATS:{ErrorTopic:error GroupName:testchain-deployment TopicPrefix:Prefix Servers:nats://nats.local:4222 MaxReconnect:3 ReconnectWaitSec:1} LogLevel:debug}" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="Start service with host: testchain-deployment, port: 5001" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="First update src started, it takes a few minutes" app=TCD

```

After the appearance of the first code block, you will have to wait between 1-15 minutes before it has fully booted. 

Once the testchain has fully booted, you will see similar output as displayed below (this will constantly update as you interact with testchain services): 

```

testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="First update src finished" app=TCD
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="Used HTTP server" app=TCD
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: GetInfo" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: Run" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: UpdateSource" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: GetResult" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: GetCommitList" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:28Z" level=info msg="HTTP method added: Checkout" app=TCD component=httpServer
testchain-deployment.local  | time="2019-04-11T08:07:38Z" level=debug msg="Request data: {\"id\":\"\",\"method\":\"RegisterDeployment\",\"data\":{\"host\":\"testchain-deployment\",\"port\":5001}}" app=TCD component=gateway_client
testchain-deployment.local  | time="2019-04-11T08:07:38Z" level=debug msg="Request data" app=TCD component=httpServer data="{}" method=GetInfo

```

Your testchain is now up and running! You are now able to start using services, such as interacting with the [testchain dashboard](https://github.com/makerdao/testchain-dashboard). 


## Full List of Testchain Commands (Docker Compose):  

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

**Note:** If you are using `docker-compose` for starting QA Dashboard from https://github.com/makerdao/testchain-backendgateway, you will have to put the 3 above files from stack_config into the `/tmp/stacks/vdb` folder on your local machine before starting the local environment.The following three files will be: 

1. Docker-compose.yml
2. Icon.png
3. Stack.json

## Installation

1. Run the `make install` command to download all of the required Docker images.
2. Set all of the config files you need automatically.

