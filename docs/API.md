# WEB API

Web API for working with QA Dashboard backend

 - `GET /chains` - List of available chains
 - `GET /snapshots/:chain_type` - List of snapshots for given chain type (`ganache`, `geth`)
 - `GET /snapshot/:id` - Get snapshot details
 - `DELETE /snapshot/:id` - Delete snapshot by it's ID
 - `GET /deployment/steps` - Load list of deployment steps
 - `GET /deployment/commits` - List of available commits
 - `GET /chain/:id` - Chain details by chain ID
 - `DELETE /chain/:id` - Remove all chain data from system (only for stopped chain !)
 - `GET /chain/stop/:id` - Stop chain by ID

## STACKS API

### Staxx configuration
Stack configuration should be placed to `:stacks_dir` configured.
By default it's configured to `/tmp/stacks`.

Stack configuration consists of 3 files under folder with stack name.

 - `stack.json` - Main stack configuration
 - `docker-compose.yml` - List of containers stack will start.
 - `icon.png` - Stack icon for QA dashboard UI

So for example for `vdb` stack you have to place it into `/tmp/stacks/vdb/stack.json`

`stack.json` file example:

```js
{
  "title": "VulcanizeDB Stack",
  "scope": "global | user | testchain",
  "manager": "testchain-vdb",
  "deps": [
    "testchain"
  ]
}
```

Property list:

 - `title` - Stack title
 - `scope` - Stack scope
 - `manager` - Stack manager service
 - `deps` - Stack dependencies

### Starting new stack
POST `/stack/start` with payload:

```js
{
  "testchain": { // <-- Testchain configs
    "config": {
      "type": "ganache", // "geth" | "geth_vdb"
      "accounts": 2, // Amount of accounts need to be created
      "block_mine_time": 0, // Block mining time
      "clean_on_stop": true, // Remove all files after chain will be stopped
      "snapshot_id": null, // Snapshot ID
      "deploy_tag": null, // tag or commit id we need to switch before deployemnt
      "step_id": 1 // deployment step
    },
    "deps": [] // For testchain we have no dependencies
  },
  "vdb": { // <-- Your stack name
    "config": {}, // No config needed to start VDB
    "deps": [  // VDB have to wait till testchain to start
      "testchain"
    ]
  }
}
```

Example:

```bash
curl --request POST \
  --url http://localhost:4000/stack/start \
  --header 'content-type: application/json' \
  --data '{
	"testchain": {
		"config": {
			"type": "ganache",
			"accounts": 2,
			"block_mine_time": 0,
			"clean_on_stop": true,
			"snapshot_id": null,
			"step_id": 1
		},
		"deps": []
	},
  "vdb": {
    "config": {},
    "deps": ["testchain"]
  }
}'
```

Response:

```js
{
  "status": 0, // 0 - success, 1 - error
  "message": "",
  "errors": [],
  "data": {
    "id": "5341658974976052158" // Generated stack ID
  }
}
```

### Stop stack
GET `/stack/stop/{stack_id}`

```bash
curl --request GET \
  --url http://localhost:4000/stack/stop/5341658974976052158
```

```json
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {}
}
```

### Stack info
Will show list of exported resources for stack
GET `/stack/info/{stack_id}`

```bash
curl --request GET \
  --url http://localhost:4000/stack/info/5341658974976052158
```

```javascript
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {
    "urls": {
      "vdb": [ // stack name
        "http://localhost:51329" // exported resource
      ]
    }
  }
}
```

### Notifications
Send any notification for stack

Route: `POST /stack/notify`
Request payload:

```js
{
  "id": "5424541485621730355", // <-- Stack ID
  "event": "stack:vdb:event", // <-- your event
  "data": {} // <-- Data you want to send
}
```

Response:

```json
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {}
}
```

Example:

```bash
curl --request POST \
  --url http://localhost:4000/stack/notify \
  --header 'content-type: application/json' \
  --data '{
	"id": "5424541485621730355",
	"event": "vdb_ready",
	"data": {}
}'
```

### Stack ready notification
Send Stack ready event

Route `POST /stack/notify/ready`
Request payload:

```js
{
  "id": "16020459699138145532", // <-- Stack ID
  "stack_name": "vdb", // <-- Stack name
  "data": {} // <-- details you need to send
}
```

Response:

```js
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {}
}
```

Example:

```bash
curl --request POST \
  --url http://localhost:4000/stack/notify/ready \
  --header 'content-type: application/json' \
  --data '{
	"id": "16020459699138145532",
	"stack_name": "vdb",
  "data": {}
}'
```

### Stack failed notification
Send Stack ready event

Route `POST /stack/notify/failed`
Request payload:

```js
{
  "id": "16020459699138145532", // <-- Stack ID
  "stack_name": "vdb", // <-- Stack name
	"data": {} // <-- details you need to send
}
```

Response:

```json
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {}
}
```

Example:

```bash
curl --request POST \
  --url http://localhost:4000/stack/notify/failed \
  --header 'content-type: application/json' \
  --data '{
	"id": "16020459699138145532",
	"stack_name": "vdb",
  "data": {}
}'
```

### Start Docker Container
Send command to start new docker container under specified stack.
All containers will be stopped when you stop stack.

Route: `POST /docker/start`

Request payload:
```js
{
  "stack_id": "2538928139759187250", // <-- Stack ID (Required)
  "stack_name": "vdb", // <-- stack name (Required)
  "image": "postgres", // <-- Docker image needs to be started (Note you have to specify it into docker-compose.yml)
  "network": "2538928139759187250", // <-- Docker network ID (Optional. Same to Stack ID)
  "cmd": "--help", // <-- See Dockerfile CMD for more details (Optional)
  "ports": [5432], // <-- Port list needs to be open for public
  "dev_mode": false, // <-- ONLY FOR TESTING ! will run container without removing it after stop.
  "env": { // <-- List of ENV variables needs to be set for docker container
    "POSTGRES_PASSWORD": "postgres"
  }
}
```

Response:
```js
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {
    "ports": [
      5432
    ],
    "network": "2538928139759187250",
    "name": "cL6dvX3sl-M9v3aIY2w6y0V1Qv1fSHAKnZN-wRsTV6soMfkS", // <-- Host name that your container is accessible in network
    "image": "postgres",
    "id": "39f2097d78495d0db552ee16c6ba6a9bbcf36ead263e198cd0f823e5e8f318d0", // <-- Container ID
    "cmd": "--help",
    "env": {
      "POSTGRES_PASSWORD": "postgres"
    }
  }
}
```

```bash
curl --request POST \
  --url http://localhost:4000/docker/start \
  --header 'content-type: application/json' \
  --data '{
	"stack_id": "2538928139759187250",
  "stack_name": "vdb",
	"image": "postgres",
	"network": "2538928139759187250",
	"ports": [5432],
	"env": {
		"POSTGRES_PASSWORD": "postgres"
	}
}'
```

**Dev mode**
By default all containers are running with `--rm` flag.
This means that as soon as container stops, system will remove it and all it's logs from system.

In case you need logs for debugging purposes you might start new container with `dev_mode: true`.
It will let Staxx know that container should not be removed from system after stop.

**Danger**
You wouldn't be able to do that in production system. `dev_mode` flag will be ignored there.
On your machine you will be responsible for removing useless containers !

Example:
```bash
curl --request POST \
  --url http://localhost:4000/docker/start \
  --header 'content-type: application/json' \
  --data '{
	"stack_id": "2538928139759187250",
  "stack_name": "vdb",
	"image": "postgres",
	"network": "2538928139759187250",
	"ports": [5432],
  "dev_mode": true,
	"env": {
		"POSTGRES_PASSWORD": "postgres"
	}
}'
```

### Chain details
For your stack you might need details of chain that was started for you.
Route: `GET /chain/{stack_id}`

It does not have any request details.
Response:

```js
{ status: 'ready', // <-- Current chain status
  id: '15511618343318382659', // <-- Stack ID (chain id is same)
  deploy_step: // <-- Deployment info for step (if it was deployed)
   { roles: [ 'CREATOR' ],
     oracles: null,
     omniaFromAddr: '0xdc9A20F5a46AFE0802b361076BeFC51f787B2e58',
     ilks: { REP: [Object], ETH: [Object] },
     id: 1,
     description: 'Step 1 - General deployment',
     defaults: {} },
  deploy_hash: '3c7bcb9961f987a924e5b79253d786249b58f700', // <-- Deployment scripts revesion
  deploy_data: // <-- List of contract addresses were deployed
   { MCD_JUG: '0x476ce78265ef96b5acd4b0c5469bebe1f1dc94d2',
     PROXY_ACTIONS: '0xbc70c384e67e3c0da83673fc46bbc4e5c1c83f67',
     MCD_VAT: '0x6e8ef6fb3fc1836e1a8364a714a8499df197d114',
     MCD_JOIN_REP: '0xfa603fefc8936e3fcc8d7bbee558232941e1eab8',
     MCD_SPOT: '0xa354bbc70caef31ab2daf0d97fe4920a2a07a9ad',
     MCD_DAI: '0x6910a5d2b7ae96db4018db7bea0b7b70bc7617b4',
     MCD_MOM_LIB: '0x1df75e2ee5581817e147f05581ff090afdc28889',
     CDP_MANAGER: '0x575340766d05915c97edee8a2fdbf71c61fd5d0e',
     MCD_PIT: '0x971c6a2ac73c8071154ad28446a65a71f27a3c5a',
     MCD_FLOP: '0x257e0053c78ead0855c4eb59e9991c0d619f22d8',
     VAL_REP: '0x7591e68a84fcf44411076712b39026eb96bf5f40',
     MCD_DEPLOY: '0xc1369ea982624e652cf39b60dbb8e78bb23663e2',
     MCD_FLAP: '0x5fdd40e4d1029d232ee90065a9ac923e01d1d9c0',
     PIP_REP: '0x7591e68a84fcf44411076712b39026eb96bf5f40',
     MCD_FLIP_REP: '0x12d9b3a2b42f71bddf81583a07f4a050d2c09821',
     VOTE_PROXY_FACTORY: '0xd6a44da55e672a34889f817a9a3b91138bfe01a8',
     PROXY_REGISTRY: '0xd8dff4ee3ac969561a088fce04f2e3bcade8ca57',
     PROXY_FACTORY: '0xca640d205f8984767a15436efaf09fe0f1f3ce85',
     MCD_MOVE_DAI: '0xf6b0c7654e4d1495cfade2d11107f96e06302d4f',
     MCD_GOV: '0x5d89865ccc5c09aaccceda332dfb5e1121c41787',
     REP: '0xb733e965071b627c99fe960c82526d0cb0921a18',
     MCD_JOIN_DAI: '0x490163610ffe5b4f16d7f17af9180b9d3968fdfb',
     PIP_ETH: '0x87958e6159d181730b696085ef42c5ff99364727',
     MCD_ADM: '0x9b82c2b8b0ea2e41cea8c0e8ab7f07622040e49f',
     MCD_MOM: '0xb2de8c29a9b97215fb412a0f280f3b2c536c80e5',
     MCD_FLIP_ETH: '0x38cf44569b78125f100a836db5b094c3f24da9b4',
     MCD_MOVE_ETH: '0xb2f1ab8901998ab503be72612cd14062e7fe0cb7',
     MCD_CAT: '0xa9a755ecb5019b8b8b1f457be1b3015f3e05c044',
     MCD_POT: '0xe4f226d6076a2b089f5263563bd42ae8d08bb37f',
     VAL_ETH: '0x87958e6159d181730b696085ef42c5ff99364727',
     MCD_VOW: '0x8f095166513f77d3a3f877615f92b7a3b9688857',
     MCD_JOIN_ETH: '0x05dc9a7524c8757d2975b4d75f2a8cb2301501b0',
     MCD_MOVE_REP: '0x9c9fd5a6d8cb9cfa0f6515b744cbf8585164b4d8',
     MCD_GOV_GUARD: '0x541e68fc8c63c21833b85022c528d876809a8224',
     MCD_DAI_GUARD: '0x867874534c8c1d1d91a51fa1f010ea23b5de5474',
     MULTICALL: '0x0692354a492a8ac91181070f9b0497809e318ce2'
  },
  config: // <-- Chain configuration details that were sent to start new chain
   { type: 'ganache', // <-- Chain type
     step_id: 1, // <-- deployment step id 0..9
     snapshot_id: null,
     node: 'ex_testchain@127.0.0.1', // <-- For internal use.
     network_id: 999, // <-- chain network ID
     id: '15511618343318382659', // <-- chain ID
     description: '',
     clean_on_stop: false,
     block_mine_time: 0,
     accounts: 2 },
  chain_details: // <-- CHain details
   { ws_url: 'ws://localhost:8554', // <-- WS RPC URl
     rpc_url: 'http://localhost:8554', // <-- JSON-RPC url
     network_id: 999, // <-- Chain network ID
     id: '15511618343318382659', // <-- Chain ID
     gas_limit: 9000000000000,
     coinbase: '0xd8db16f114488f071bf9e1008b49d07e2a064ebd', // <-- Coinbase account
     accounts: [ /* ... */ ] // <-- List of created accounts with their private keys and addresses
   }
 }
```

### Reload stacks configuration
In case of some changes in stack configuration you might need to reload stacks configurations.
It could be done by calling `GET /stack/reload` route.

```bash
curl --request GET \
  --url http://localhost:4000/stack/reload
```
It does not have any request details.
Response:

```json
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {}
}
```

### Get list of available stacks
For some reason you might need list of available stacks configs.

Request:
```bash
curl --request GET \
  --url http://localhost:4000/stack/list
```

Response example:
```json
{
  "status": 0,
  "message": "",
  "errors": [],
  "data": {
    "helloworld": {
      "title": "Hello World Stack",
      "scope": "global",
      "name": "helloworld",
      "manager": "makerdao/testchain-stack-helloworld",
      "deps": [
        "testchain"
      ],
      "containers": {
        "display": {
          "ports": [
            3000
          ],
          "image": "makerdao/testchain-stack-helloworld-display"
        }
      }
    }
  }
}
```
