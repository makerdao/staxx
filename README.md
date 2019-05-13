# TestchainBackend
[![Build Status](https://travis-ci.org/makerdao/testchain-backendgateway.svg?branch=master)](https://travis-ci.org/makerdao/testchain-backendgateway)

## Docker compose

1. Build all images in all repo
2. Use `make dc-up` for run
3. Use `make dc-down` for down with removing of data

Instead of 2 and 3 u can use `docker-compose` cmd in console.

## Deployment service

```elixir
iex(6)> Proxy.Deployment.BaseApi.request("test", "get_info")
{:error,
 %{
   "code" => "notFound",
   "detail" => "Unknown method: get_info",
   "errorList" => []
 }}
iex(7)> Proxy.Deployment.BaseApi.request("test", "GetInfo")
{:ok,
 %{
   "result" => %{
     "steps" => [
       %{
         "defaults" => %{"osmDelay" => "1"},
         "description" => "Step 7 - MS 3 - Crash & Bite",
         "id" => 1,
         "oracles" => [
           %{"contract" => "MEDIANIZER_ETH", "symbol" => "ETH"},
           %{"contract" => "MEDIANIZER_REP", "symbol" => "REP"}
         ],
         "roles" => ["CREATOR", "CDP_OWNER"]
       }
     ],
     "tagHash" => "f1e23cd2aecb42ddb74f29eb7db576f21b1911d9"
   },
   "type" => "ok"
 }}
```

## Local docker-compose env

To start everything in docker on your local machine there is set of make commands.
Everything is wrapped into `docker-compose-dev.yml` file. So you have to have `docker-compose`
installed on your machine.

Commands:

 - `make run-dev` - Will start QA portal in docker images and will set `localhost:4001` - for UI and `localhost:4000` - for WS/Web API
 - `make logs-dev` - Will spam you with logs from system
 - `make logs-deploy` - Will show list of logs for deployment service
 - `make stop-dev` - Will stop all services
 - `make rm-dev` - Will remove local containers (NOT IMAGES, ONLY CONTAINERS !)
 - `make upgrade-dev` - Will stopp all running containers and remove them as well as images

**NOTE**:
Deployment service have to download latest sources of deployment contracts and update `dapp` dependencies
So It will take pretty long (up to 15 minutes).

To monitor this process you could use command `make logs-deploy`

```bash
master ✓ make logs-deploy
Attaching to testchain-deployment.local
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="Config loaded" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=debug msg="Config: &{Server:HTTP Host:testchain-deployment Port:5001 Deploy:{DeploymentDirPath:/deployment DeploymentSubPath:./ ResultSubPath:out/addresses.json} Gateway:{Host:testchain-backendgateway.local Port:4000 ClientTimeoutInSecond:5 RegisterPeriodInSec:10} Github:{RepoOwner:makerdao RepoName:testchain-dss-deployment-scripts DefaultCheckoutTarget:tags/qa-deploy} NATS:{ErrorTopic:error GroupName:testchain-deployment TopicPrefix:Prefix Servers:nats://nats.local:4222 MaxReconnect:3 ReconnectWaitSec:1} LogLevel:debug}" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="Start service with host: testchain-deployment, port: 5001" app=TCD
testchain-deployment.local  | time="2019-04-11T07:56:14Z" level=info msg="First update src started, it takes a few minutes" app=TCD
```

This logs mean service still downloading...

After it will be ready you will see this in logs:

```bash
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

That will mean your service is ready to work :sunglasses:

## Setting up stacks

For now we support only `vdb` stack available
[Github VDB repo](https://github.com/makerdao/testchain-stack-vdb)

To set it up locally you have to place all files from [stack_config](https://github.com/makerdao/testchain-stack-vdb/tree/master/stack_config) to `/tmp/stacks/vdb` (if you didn't change anything)

