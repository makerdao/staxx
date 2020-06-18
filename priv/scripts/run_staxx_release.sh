#!/bin/bash
MIX_ENV=prod \
DOCKER_DEV_MODE_ALLOWED=true \
NATS_URL=127.0.0.1 \
DEPLOYMENT_SERVICE_URL=http://127.0.0.1:5001/rpc \
CHAINS_FRONT_URL=localhost \
CHAINS_DB_PATH=/tmp/chains \
EXTENSIONS_DIR=/tmp/extensions \
FRONT_URL=localhost \
SNAPSHOTS_DB_PATH=/tmp/snapshots \
RELEASE_COOKIE="W_cC]7^rUeVZc|}$UL{@&1sQwT3}p507mFlh<E=/f!cxWI}4gpQx7Yu{ZUaD0cuK" \
RELEASE_NODE=staxx@127.0.0.1 \
PORT=4000 \
_build/prod/rel/staxx/bin/staxx start_iex
