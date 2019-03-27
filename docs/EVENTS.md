# Testchain events

When you work with testchain/stacks you will receive set of event from system.
All events has format:

```js
{
  "id": "2538928139759187250", // <-- Stack/chain ID
  "event": "ready", // <-- Stack/chain event name
  "data": {} // <-- Event details
}
```

List of available events:

 - `initializing` - Chain starting
 - `ready` - Chain ready
 - `deployed` - Deployment process finished
 - `terminating` - Termination process started
 - `terminated` - Chain terminated
 - `locked` - Chain locked for some internal action (not operational)
 - `failed` - Something wrong
 - `snapshot_taken` - Chain Snapshot taken
 - `snapshot_reverted` - Chain Snapshot reverted
 - `stack:ready` - Stack ready
 - `stack:failed` - Stack failed

Chain ready event example:
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
   "event":"ready",
   "id":"15511618343318382659"
}
```

Deployed example:
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
