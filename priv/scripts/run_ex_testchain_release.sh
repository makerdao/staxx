#!/bin/bash
MIX_ENV=prod \
DOCKER_DEV_MODE_ALLOWED=true \
NATS_URL=127.0.0.1 \
DEPLOYMENT_SERVICE_URL=http://127.0.0.1:5001/rpc \
CHAINS_FRONT_URL=localhost \
CHAINS_DB_PATH=/tmp/chains \
STACKS_DIR=/tmp/stacks \
SNAPSHOTS_DB_PATH=/tmp/snapshots \
GANACHE_EXECUTABLE=priv/presets/ganache-cli/cli.js \
GANACHE_WRAPPER=priv/presets/ganache/wrapper.sh \
EVM_ACCOUNT_PASSWORD=priv/presets/geth/account_password \
GETH_VDB_EXECUTABLE=priv/presets/geth/geth_vdb \
RELEASE_COOKIE="W_cC]7^rUeVZc|}$UL{@&1sQwT3}p507mFlh<E=/f!cxWI}4gpQx7Yu{ZUaD0cuK" \
RELEASE_NODE=ex_testchain@127.0.0.1 \
STAXX_NODE=staxx@127.0.0.1 \
_build/prod/rel/ex_testchain/bin/ex_testchain start_iex
