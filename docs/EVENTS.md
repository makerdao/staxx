# Testchain events

When you work with testchain/extensions you will receive set of event from system.
All events has similar format:

```js
{
  "id": "2538928139759187250", // <-- Extension/chain ID
  "event": "ready", // <-- Extension/chain event name
  "data": {} // <-- Event details
}
```

But there are several main events you will need to controll environment:

 - `status_changed` - Testchain (EVM) changed it's status [More info](#evm-statuses)
 - `started` - EVM Started event. **EVM not ready yet !** [More details](#evm-started)
 - `deployed` - Deployment process finished sucessfully. [More details](#deployment-finished)
 - `deployment_failed` - Deployment process failed. [More details](#deployment-failed)
 - `snapshot_taken` - Snapshot taken sucessfuly. [More details](#snapshot-taken)
 - `snapshot_reverted` - Snapshot reverted sucessfuly. [More details](#snapshot-reverted)
 - `error` - Error happened in system [More details](#evm-error)
 - `terminated` - EVM terminated [More details](#evm-terminated)
 - `extension:ready` - Extension ready
 - `extension:failed` - Extension failed

### EVM Statuses

EVM status change event:

```js
{
   "data":{
      "status": "active"
   },
   "event":"status_changed",
   "id":"15511618343318382659"
}
```

More detailed view of statuses flow could be found [here](#statuses-flow)
List of available Testchain (EVM) statuses:

 - `initializing` - EVM starting
 - `active` - EVM became active but not fully ready to be used (additional actions like deployments might be needed)
 - `deploying` - Deployment process started (EVM is not ready yet)
 - `deployment_failed` - Deployment process failed something wrong with deployment.
 - `deployment_success` - Deployment process finished successfully
 - `terminating` - Termination process started
 - `terminated` - EVM terminated
 - `failed` - EVM failed something went wrong (After this EVM will be terminated)
 - `snapshot_taking` - EVM Snapshot taking process started
 - `snapshot_taken` - EVM Snapshot taken
 - `snapshot_reverting` - EVM Snapshot reverting process started
 - `snapshot_reverted` - EVM Snapshot reverted
 - `ready` - EVM finally operational and fully ready to be used

### EVM Started

`started` event means that EVM started successfully.
`data` section of event will contain list of EVM details like JSON-RPC urls and created accounts.
**NOTE:** EVM is active but not yet operational. More tasks might be performed after this event.

EVM started event example:

```js
{
   "data":{
      "accounts":[
         {
            "address":"0xd8db16f114488f071bf9e1008b49d07e2a064ebd",
            "balance":100000000000000000000000,
            "priv_key":"711d4fa5fa9297f8f7e39b816cc8152f512b8b83467c0b658b2de181f6008f42"
         },
         {
            "address":"0xf2f1c7b1540d6d85c402598d7583d221ae1faf5a",
            "balance":100000000000000000000000,
            "priv_key":"bf78b8bb547ab19e6bb46d1ba394e22901fdeac44061b25179f950e5ddf9a2ef"
         },
         {
            "address":"0x7fc3d7e58ecb856aa3d18468c22411d05dbc2af0",
            "balance":100000000000000000000000,
            "priv_key":"10bc190af3250c56e890481a39989680a18e574a581954c919e716dd526725e9"
         }
      ],
      "coinbase":"0xd8db16f114488f071bf9e1008b49d07e2a064ebd",
      "gas_limit":9000000000000,
      "id":"15511618343318382659",
      "network_id":999,
      "rpc_url":"http://localhost:8554",
      "ws_url":"ws://localhost:8554"
   },
   "event":"started",
   "id":"15511618343318382659"
}
```

### EVM error
Some error happened during EVM operations.
For some errors EVM will be terminated (like errors on EVM start/initialization), but for others - not.

Error event example:
```js
{
  id: "15511618343318382659", // <- Extension/Testchain ID
  event: "error",
  data: {
     "message": "Some error message from system..."
  }
}
```

### EVM terminated

This event will be fired every time EVM terminated

```js
{
  id: "15511618343318382659",
  event: "terminated",
  data: {}
}
```

### Deployment finished

Deployment process finished succesfuly and add deployed contracts will re sent as `data` field.
EVM is not yet operational. You have to wait for [ready status](#evm-statuses)

Deployed event example:
```js
{
   "data":{
      "MULTICALL":"0x0692354a492a8ac91181070f9b0497809e318ce2",
      "MCD_DAI_GUARD":"0x867874534c8c1d1d91a51fa1f010ea23b5de5474",
      "MCD_GOV_GUARD":"0x541e68fc8c63c21833b85022c528d876809a8224",
      "MCD_MOVE_REP":"0x9c9fd5a6d8cb9cfa0f6515b744cbf8585164b4d8",
      "MCD_JOIN_ETH":"0x05dc9a7524c8757d2975b4d75f2a8cb2301501b0",
      "MCD_VOW":"0x8f095166513f77d3a3f877615f92b7a3b9688857",
      "VAL_ETH":"0x87958e6159d181730b696085ef42c5ff99364727",
      "MCD_POT":"0xe4f226d6076a2b089f5263563bd42ae8d08bb37f",
      "MCD_CAT":"0xa9a755ecb5019b8b8b1f457be1b3015f3e05c044",
      "MCD_MOVE_ETH":"0xb2f1ab8901998ab503be72612cd14062e7fe0cb7",
      "MCD_FLIP_ETH":"0x38cf44569b78125f100a836db5b094c3f24da9b4",
      "MCD_MOM":"0xb2de8c29a9b97215fb412a0f280f3b2c536c80e5",
      "MCD_ADM":"0x9b82c2b8b0ea2e41cea8c0e8ab7f07622040e49f",
      "PIP_ETH":"0x87958e6159d181730b696085ef42c5ff99364727",
      "MCD_JOIN_DAI":"0x490163610ffe5b4f16d7f17af9180b9d3968fdfb",
      "REP":"0xb733e965071b627c99fe960c82526d0cb0921a18",
      "MCD_GOV":"0x5d89865ccc5c09aaccceda332dfb5e1121c41787",
      "MCD_MOVE_DAI":"0xf6b0c7654e4d1495cfade2d11107f96e06302d4f",
      "PROXY_FACTORY":"0xca640d205f8984767a15436efaf09fe0f1f3ce85",
      "PROXY_REGISTRY":"0xd8dff4ee3ac969561a088fce04f2e3bcade8ca57",
      "VOTE_PROXY_FACTORY":"0xd6a44da55e672a34889f817a9a3b91138bfe01a8",
      "MCD_FLIP_REP":"0x12d9b3a2b42f71bddf81583a07f4a050d2c09821",
      "PIP_REP":"0x7591e68a84fcf44411076712b39026eb96bf5f40",
      "MCD_FLAP":"0x5fdd40e4d1029d232ee90065a9ac923e01d1d9c0",
      "MCD_DEPLOY":"0xc1369ea982624e652cf39b60dbb8e78bb23663e2",
      "VAL_REP":"0x7591e68a84fcf44411076712b39026eb96bf5f40",
      "MCD_FLOP":"0x257e0053c78ead0855c4eb59e9991c0d619f22d8",
      "MCD_PIT":"0x971c6a2ac73c8071154ad28446a65a71f27a3c5a",
      "CDP_MANAGER":"0x575340766d05915c97edee8a2fdbf71c61fd5d0e",
      "MCD_MOM_LIB":"0x1df75e2ee5581817e147f05581ff090afdc28889",
      "MCD_DAI":"0x6910a5d2b7ae96db4018db7bea0b7b70bc7617b4",
      "MCD_SPOT":"0xa354bbc70caef31ab2daf0d97fe4920a2a07a9ad",
      "MCD_JOIN_REP":"0xfa603fefc8936e3fcc8d7bbee558232941e1eab8",
      "MCD_VAT":"0x6e8ef6fb3fc1836e1a8364a714a8499df197d114",
      "PROXY_ACTIONS":"0xbc70c384e67e3c0da83673fc46bbc4e5c1c83f67",
      "MCD_JUG":"0x476ce78265ef96b5acd4b0c5469bebe1f1dc94d2"
   },
   "event":"deployed",
   "id":"15511618343318382659"
}
```

### Deployment failed

Deployment process failed.
EVM is not yet operational but it wouldn't be terminated. So you could debug contracts.
You have to wait for [ready status](#evm-statuses)

Deployment failed event example:
```js
{
  id: "15511618343318382659", // <- Extension/Testchain ID
  event: "deployment_failed",
  data: {
     "error": "tones of logs from scripts..."
  }
}
```

### Snapshot taken

Snapshot sucessfuly taken for EVM.
On this step EVM is not operational and it will go through starting process again.
You will have to wait `active` and `ready` status.
[Stagted event](#evm-started) will be fired as well.

Snapshot taken event example:

```js
{
  id: "15511618343318382659", // <- Extension/Testchain ID
  event: "snapshot_taken",
  data: {
      chain: "ganache" // <- EVM type
      date: "2020-01-10T13:58:16.287549Z" // <- Snapshot taked date
      description: "test 2" // <- Description you passed on take_snapshot command
      id: "17539000027403163896" // <- Snapshot ID. It will be different to scope/testchain id
      path: "/tmp/snapshots/17539000027403163896.tgz" // <- Snapshot stored path (internal)
  }
}
```

### Snapshot reverted

Snapshot sucessfuly reverted for EVM.
On this step EVM is not operational and it will go through starting process again.
You will have to wait `active` and `ready` status.
[Stagted event](#evm-started) will be fired as well.

Snapshot reverted event example:

```js
{
  id: "15511618343318382659", // <- Extension/Testchain ID
  event: "snapshot_reverted",
  data: { // <- Reverted snapshot details
      chain: "ganache" // <- EVM type
      date: "2020-01-10T13:58:16.287549Z" // <- Snapshot taked date
      description: "test 2" // <- Description you passed on take_snapshot command
      id: "17539000027403163896" // <- Snapshot ID. It will be different to scope/testchain id
      path: "/tmp/snapshots/17539000027403163896.tgz" // <- Snapshot stored path (internal)
  }
}
```

### Extension status event
This event will be fired every time extension changes it's status

```js
{
  id: "15511618343318382659",
  event: "extension:status",
  data: {
    "scope_id": "15511618343318382659",
    "extension_name": "some_extension_name",
    "status": "ready" // "failed", "initializing", "terminate"
  }
}
```

### Statuses flow
Here is default status flow for EVM:

![Events Flow](./statuses_flow.png)
