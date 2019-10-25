#!/bin/bash
docker run -it --rm --network staxx_net1 \
        -e "REQUEST_ID=test" \
        -e 'DEPLOY_ENV={"ETH_FROM":"0x17ae02b6145fc542cbdd00c4367ce2e4f18da059","ETH_GAS":"17000000","ETH_RPC_URL":"http://host.docker.internal:8585","ETH_RPC_ACCOUNTS":"yes"}' \
        -e "GITHUB_DEFAULT_CHECKOUT_TARGET=refs/tags/staxx-deploy" \
        -e "REPO_URL=https://github.com/makerdao/dss-deploy-scripts" \
        -e "REPO_REF=refs/tags/staxx-deploy" \
        -e "SCENARIO_NR=1" \
        --env TCD_GATEWAY="host=host.docker.internal" \
        --env TCD_NATS="servers=nats://nats.local:4222" \
        -v nix-db:/nix \
        makerdao/testchain-deployment-worker:dev
