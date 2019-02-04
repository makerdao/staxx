## Starting backend
Rather than start `ex_testchain` docker image. now there is [Docker compose file](./docker-compose.yaml)
And now you could place this file whereever you want and run `docker-compose up -d` command from this folder.

**Note** it will start 3 docker images and one of them `makerdao/testchain-deployment` will take several minutes
to load (it have to download dss deployment scripts).

You could check using command `docker logs -f testchain-deployment.local`

You should wait for logs similar to this:
```
time="2019-02-04T20:10:46Z" level=debug msg="Loaded data: \n 100499371a1c30568753d96ed90b8b3412401078 \n\n [{ID:1 Description:Step 1 - General deployment Defaults:[123 125] Roles:[91 34 67 82 69 65 84 79 82 34 93] Oracles:[]} {ID:4 Description:Step 4 - CDP Management Defaults:[123 32 34 111 115 109 68 101 108 97 121 34 58 32 34 48 34 32 125] Roles:[91 34 67 82 69 65 84 79 82 34 93] Oracles:[]} {ID:7 Description:Step 4 - Market Crash & CDP Bite Defaults:[123 32 34 111 115 109 68 101 108 97 121 34 58 32 34 48 34 32 125] Roles:[91 34 67 82 69 65 84 79 82 34 93] Oracles:[]}]" app=TCD
```

## Start chain
2 new properties are added into start options:
`snapshot_id` - If you plan to start chain and deploy snapshot from beginning. (not really needed for demo)
`step_id` - Integer `1-9` (need to load list of steps). Step ID to deploy when starting new chain.

**Note** Deployment process might take several minutes

## List of steps

There is new HTTP route `/deployment/steps` returning list of available steps for system

## Events

Major changes are into events part of system.

First of all right now there are 2 types of statuses.
One for chain status (`status_changed` events).
And system events like: `started`, `deploying`, `deployed`, `deployment_failed`, `ready`, `failed`

Chain is ready only when `ready` event is fired. Before this event it might be deployment process running.

## New chain lifecircle after starting new chain:
`:starting` -> `:started` -> `:deploying` -> (`:deployed` | `:deployment_failed`) -> `:ready`

All this events will be fired into `chain:#{id}` channel.

## Examples

Deploying event:

```
channel: "chain:17501195497559030843",
event: "deploying",
data: {"ws_url":"ws://host.docker.internal:8584","rpc_url":"http://host.docker.internal:8584","id":"17501195497559030843","gas_limit":9000000000000,"coinbase":"0x594cbb5e94d6bf2fc1b765ae81d3aed00385496d","accounts":[{"priv_key":"f1051e212d3b3b3b9254db8ea3c8fd8bf3a53fe28133b87d519652ee22bc3b39","balance":100000000000000000000,"address":"0x594cbb5e94d6bf2fc1b765ae81d3aed00385496d"},{"priv_key":"e683ef68560a69f3a66c5c949e890e0b180a2dcb0111a427057dfcd5884a05f2","balance":100000000000000000000,"address":"0xe9e80dcc40e7d9a39e8930d168a0dca5b6f3849e"},{"priv_key":"d94f0303b861b32b41bc086c3d0f2487600f6260fe6c06e957e490cef9087b46","balance":100000000000000000000,"address":"0x78bc0336e277aa2ba0cdacbb90257b602f8061c8"}]}
```
