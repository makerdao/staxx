#!/bin/bash
docker run -it --rm --network d4f97b46c61f \
        -e "REQUEST_ID=test" \
        -e 'DEPLOY_ENV={"ETH_FROM":"0x0ad2099deef7a76273c8b0699b60fe367522f183","ETH_GAS":"17000000","ETH_RPC_URL":"http://host.docker.internal:8570","ETH_RPC_ACCOUNTS":"yes"}' \
        -e "GITHUB_DEFAULT_CHECKOUT_TARGET=tags/staxx-deploy" \
        -e "REPO_URL=https://github.com/makerdao/dss-deploy-scripts" \
        -e "REPO_REF=tags/staxx-deploy" \
        -e "SCENARIO_NR=1" \
        --env TCD_GATEWAY="host=host.docker.internal" \
        --env TCD_NATS="servers=nats://host.docker.internal:4222" \
        -v nix-db:/nix \
        makerdao/testchain-deployment-worker:dev
