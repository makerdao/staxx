# WEB API

Web API for working with QA Dashboard backend

## STACKS API

### Stacks configuration
Stack configuration should be placed to `:stacks_dir` configured.
By default it's configured to `/tmp/stacks`.

Stack configuration consists of 3 files under folder with stack name.

 - `stack.json` - Main stack configuration
 - `docker-compose.yml` - List of containers stack will start.
 - `icon.png` - Stack icon for QA dashboard UI

So for example for `vdb` stack you have to place it into `/tmp/stacks/vdb/stack.json`

`stack.json` file example:

```javascript
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

```json
{
  "testchain": { // <-- Testchain configs
    "config": {
      "type": "ganache", // "geth" | "geth_vdb"
      "accounts": 2, // Amount of accounts need to be created
      "block_mine_time": 0, // Block mining time
      "clean_on_stop": true, // Remove all files after chain will be stopped
      "snapshot_id": null, // Snapshot ID
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

```json
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

### Notifications
Send any notification for stack

Route: `POST /stack/notify`
Request payload:

```json
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

```json
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

```json
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
```json
{
  "stack_id": "2538928139759187250", // <-- Stack ID (Required)
  "stack_name": "vdb", // <-- stack name (Required)
  "image": "postgres", // <-- Docker image needs to be started (Note you have to specify it into docker-compose.yml)
  "network": "2538928139759187250", // <-- Docker network ID (Optional. Same to Stack ID)
  "ports": [5432], // <-- Port list needs to be open for public
  "env": { // <-- List of ENV variables needs to be set for docker container
    "POSTGRES_PASSWORD": "postgres"
  }
}
```

Response:
```json
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
	"image": "postgres",
	"network": "2538928139759187250",
	"ports": [5432],
	"env": {
		"POSTGRES_PASSWORD": "postgres"
	}
}'
```
