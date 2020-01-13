# WEB API

**Better take a look into Postman collection**

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
 - `POST /chain/:id/take_snapshot` - Start taking snapshot (result will be received by WS)
 - `POST /chain/:id/revert_snapshot/snapshot_id` - Start reverting snapshot (result will be received by WS)

## Postman APIs and Envs

There are exported Postman environments available [here](./postman)

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
{
    "data": {
        "id": "3739945501380195810",
        "title": "3739945501380195810",
        "node_type": "geth",
        "status": "ready",
        "config": {
            "accounts": 1,
            "block_mine_time": 0,
            "clean_on_stop": true,
            "db_path": "/tmp/chains/3739945501380195810",
            "deploy_ref": "refs/tags/staxx-testrunner",
            "deploy_step_id": 1,
            "description": "",
            "gas_limit": 9000000000000,
            "id": "3739945501380195810",
            "network_id": 999,
            "snapshot_id": null,
            "type": "geth"
        },
        "details": {
            "accounts": [
                {
                    "address": "0xa0e2d8f00176095631a7ca4ab0798e9fb0cf14d1",
                    "balance": 100000000000000000000000,
                    "priv_key": "d15d789a0352139cf779e379152cf6beb9e9fae61c41fa26a2313734adc6b245"
                }
            ],
            "coinbase": "0xa0e2d8f00176095631a7ca4ab0798e9fb0cf14d1",
            "gas_limit": 9000000000000,
            "id": "3739945501380195810",
            "network_id": 999,
            "rpc_url": "http://localhost:58216",
            "ws_url": "ws://localhost:57918"
        },
        "deployment": {
            "git_ref": "refs/tags/staxx-testrunner",
            "request_id": "5430791605818130655698",
            "step_id": 1,
            "result": {
                "MULTICALL": "0x0c0ad748579f6b1e18fee512a232a5143647b5dc",
                "GET_CDPS": "0xfeaecbff78491b041340aeb3d1296a7f4d2ec50e",
                "MCD_FLIP_BAT_A": "0xadc47b5f8a450316719a887d89a5552f2dd1fed4",
                "PROXY_ACTIONS_END": "0x6b5faf8b4351068d896e9ba4ee1119ba20171ac3",
                "MCD_FLIP_DGD_A": "0x6011ae632f4bf21f58e8844ec595bbf92c066948",
                "VOTE_YES": "0xdbfe2b1c563a87fc54ae6d6007d4c2eb9ec9267c",
                "DEPLOYER": "0xa0e2d8f00176095631a7ca4ab0798e9fb0cf14d1",
                "MCD_VOW": "0x6c8e84ce11fe6ecdcf814a74d77618821a0824be",
                "MCD_END": "0xa29804a707b84eba51448c2ba075a98feb910c7b",
                "VAL_BAT": "0x24f7028845a513caaab1342bf637b630e6ddacd7",
                "MCD_JOIN_ETH_C": "0x9d2fd7e6d23a4ec35dd3b9e87a3018a7464c3df9",
                "GOV_POLL_GEN": "0xa3c2316fd3bc0745d86572dc782e2d93089006a7",
                "VAL_ETH": "0x3167f611efbde35d61f9668cf8ac8ef4f69b1e2f",
                "MCD_POT": "0xa8767ae5b34105798e3014ebf475239e15fd167d",
                "MCD_CAT": "0xf4d2bd0a7487dd7245b1ac464938485c6a1e3ea6",
                "ZRX": "0xd779314e94cd802395c84c8ff45ce49c69691339",
                "MCD_FLIP_GNT_A": "0xe280578fbc67479e799f5b8de390554fb4bf6d04",
                "MCD_JOIN_ETH_B": "0xad4dc5300b9ee864452d0a8e0ef9f27fc0c4f012",
                "MCD_JOIN_OMG_A": "0x30c78754362fa42146053146a949874883f5058f",
                "MCD_FLIP_ETH_C": "0x64ecdd73092a69bb411620a4cbbf543112814dcd",
                "MCD_ADM": "0xd1da413e9e908b847e49269debb15bb43c7765ca",
                "PIP_ETH": "0x3167f611efbde35d61f9668cf8ac8ef4f69b1e2f",
                "MCD_JOIN_DAI": "0xfcefad0c052aaf592c924ae6913b66259b001728",
                "REP": "0x2dd5eaf253cfc364fb6dfa55f6d71b690cd2de87",
                "MCD_FLIP_ETH_B": "0xef588ad4135f99a7d38073b02c11c0e9c444c06f",
                "MCD_GOV": "0x8e27bd4c6ecccef8ca4b2054461b2a1cfaf50c12",
                "PROXY_FACTORY": "0x9f5c0c97e196f63e8c740c14612daa95f4831c68",
                "ETH": "0xb6988b92ee20d8488e72653c16a82eb04ae84ed4",
                "PROXY_REGISTRY": "0x493d27704c8726a6b1e23ffa60decd6b17342ab8",
                "MCD_FLIP_ZRX_A": "0x1c66010e3993532e30915bdfbe6092fed597acc8",
                "VOTE_PROXY_FACTORY": "0x48b65c9caddce88ad8815e5983501abf9d91be2c",
                "MCD_JOIN_REP_A": "0x0d592421259aa5b93f49f76db677939d78b787dc",
                "VOTE_NO": "0xe432ddff0665362ed3132a0b7b29b9384ab503dd",
                "PIP_REP": "0x63808ac10fc94aa328da7c2d3f7ce30f063bab1b",
                "MCD_FLAP": "0xcf57ec8952d7c64368a65baa1cef6e7be65a5495",
                "MCD_DEPLOY": "0x5a45dc1fdb0aa3672c6829d2f7d3e10acc7bc412",
                "VAL_REP": "0x63808ac10fc94aa328da7c2d3f7ce30f063bab1b",
                "PROXY_ACTIONS_DSR": "0xbb3121048c396ac8e66fa477b3ebccf6c573ad2d",
                "PIP_BAT": "0x24f7028845a513caaab1342bf637b630e6ddacd7",
                "MCD_JOIN_ETH_A": "0x3c4f920f486bbb040e5d8df8219c4daa264bf076",
                "MCD_FLOP": "0x03496bc6c43b30e44e3236f92984e0e63ebad0d4",
                "MCD_FLIP_ETH_A": "0x610852bf1b0716c996fde15732577b9ebe8da497",
                "MCD_ESM": "0x89a48660b0c609591e559d7697363ac4802e696b",
                "MCD_JOIN_ZRX_A": "0xb714c3726fac3f80c78859913402a609f0ca68f4",
                "BAT": "0x8dca07a80fb7886d147d78464e4f9aabf8a3c376",
                "MCD_PAUSE": "0xa85817477be2ca972a93b9c120cb85c9fa9b12f8",
                "VAL_DGD": "0x4e1555359816ee79760bb12940282698e3c71b92",
                "MCD_FLIP_OMG_A": "0x291ce3de728d32ffc4e47d8a705c94660fce1b1d",
                "CDP_MANAGER": "0x3b8df4521e53fe81868c6dc38bc398b0f89fef18",
                "MCD_GOV_ACTIONS": "0x3a7c221bece1b6581f2e8d6fbefc87fd930acffb",
                "PROXY_DEPLOYER": "0x7bd671095e6c5c93bd0e4e8ce680121709402a20",
                "VAL_ZRX": "0x27856c3a5162acbcbcf76a0024a2825ed93a773d",
                "MCD_JOIN_DGD_A": "0x44a9bf4048684bbe93405f47231cf5c6f6ae69bc",
                "POLL_ID": "0",
                "PROXY_PAUSE_ACTIONS": "0x3c43dc7147e9a274d89389a81c0cf54967c5de50",
                "VAL_GNT": "0x5979bf10c0f8e87b9c8cf4a917d67268e099cd5f",
                "MCD_DAI": "0xddd11de117797b63ca31fb147692f28ca09011e2",
                "MCD_PAUSE_PROXY": "0x12b6b2393c079000e06cd949c561e2d1552491fa",
                "MCD_SPOT": "0xef0dee5302c0deb4de3bd953b516df166294c7a9",
                "FAUCET": "0xc83cb93fbeb11b4b089a8867ae7914827abaeb77",
                "PIP_OMG": "0xf41e229e0c27f3f103d81e18363804227030561d",
                "MCD_FLIP_REP_A": "0x24af2e221f80c9b82fd4a80af3ccabebe233e6c9",
                "MCD_IOU": "0x16f44d6282e632de0a3b1cb771295e95e74da89e",
                "PIP_GNT": "0x5979bf10c0f8e87b9c8cf4a917d67268e099cd5f",
                "VAL_OMG": "0xf41e229e0c27f3f103d81e18363804227030561d",
                "MCD_JOIN_BAT_A": "0x3acf896e3e35ac13e174416bbeb4eea210fef9d3",
                "GNT": "0x02d9d58baaed21de723c1279a802aa8a44c862d2",
                "MCD_JOIN_GNT_A": "0x042a9eee21f7f45b10f3872352eecdf132f5fcbe",
                "GOV_GUARD": "0x7269717e66786e19f1b508e897099a2728c10dd9",
                "PIP_ZRX": "0x27856c3a5162acbcbcf76a0024a2825ed93a773d",
                "PIP_DGD": "0x4e1555359816ee79760bb12940282698e3c71b92",
                "MCD_VAT": "0x73fc3160c298db9afc18bc70a1584d4c974e6063",
                "DGD": "0x7f51177aea2e9b14f3a15dc33d6e0942dbb91004",
                "OMG": "0x713204f9fab7862e257908d3fa8690a78c52f338",
                "PROXY_ACTIONS": "0x4e33380634768f4e470d66eaba874c13210b675c",
                "MCD_JUG": "0xaf49bf671539afc2a1daa5508335231755cc0f06"
            }
        }
    },
    "errors": [],
    "message": "",
    "status": 0
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

### Get list of axisting chains

Load list of chains existing in system

```bash
curl --location --request GET 'http://localhost:4000/chains'
```

```json
{
    "data": [
        {
            "id": "5255695394902452494",
            "title": "5255695394902452494",
            "node_type": "geth",
            "status": "ready",
            "config": {
                "accounts": 2,
                "block_mine_time": 0,
                "clean_on_stop": true,
                "db_path": "/tmp/chains/5255695394902452494",
                "deploy_ref": "refs/tags/staxx-testrunner",
                "deploy_step_id": 0,
                "description": "",
                "gas_limit": 9000000000000,
                "id": "5255695394902452494",
                "network_id": 999,
                "snapshot_id": null,
                "type": "geth"
            },
            "details": {
                "accounts": [
                    {
                        "address": "0x8a06769d94cb75014ec7b514ef31987b3c948667",
                        "balance": 100000000000000000000000,
                        "priv_key": "48de33e0f192268c850caae2caa9de07b20ba54315efc7f1b0fcba279254f06e"
                    },
                    {
                        "address": "0x46900d6333ffd15498b1a1983310a6111ed138ed",
                        "balance": 100000000000000000000000,
                        "priv_key": "0c556d3b861b3d6e3f24f36aa62c842cf74bdfafed4461641770e09f53ffd031"
                    }
                ],
                "coinbase": "0x8a06769d94cb75014ec7b514ef31987b3c948667",
                "gas_limit": 9000000000000,
                "id": "5255695394902452494",
                "network_id": 999,
                "rpc_url": "http://localhost:63185",
                "ws_url": "ws://localhost:50968"
            },
            "deployment": {}
        }
    ],
    "errors": [],
    "message": "",
    "status": 0
}
```
