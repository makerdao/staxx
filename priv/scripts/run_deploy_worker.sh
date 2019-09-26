#!/bin/bash
docker run -it --rm --network d4f97b46c61f \
        -e "REQUEST_ID=test" \
        -e 'DEPLOY_ENV={"ETH_FROM":"0xfd2f0f26f632f6572ced6cd17b12289690bbebea","ETH_GAS":"17000000","ETH_RPC_URL":"http://host.docker.internal:8558","ETH_RPC_ACCOUNTS":"yes"}' \
        -e "GITHUB_DEFAULT_CHECKOUT_TARGET=tags/staxx-deploy" -e "REPO_URL=https://github.com/makerdao/dss-deploy-scripts" \
        -e "REPO_REF=tags/staxx-deploy" \
        -e "SCENARIO_NR=1" \
        --env TCD_GATEWAY="host=host.docker.internal" \
        -v nix-db:/nix \
        makerdao/testchain-deployment-worker:dev
