# The version of Alpine to use for the final image
ARG ALPINE_VERSION=3.9

FROM elixir:1.9.0-alpine as builder

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG APP_NAME=staxx
# The version of the application we are building (required)
ARG APP_VSN=0.1.0
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    git \
    bash \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

# This copies our app mix.exs and mix.lock source code into the build container
COPY mix.* ./
COPY apps/deployment_scope/mix.* ./apps/deployment_scope/
COPY apps/docker/mix.* ./apps/docker/
COPY apps/event_stream/mix.* ./apps/event_stream/
COPY apps/ex_chain/mix.* ./apps/ex_chain/
COPY apps/json_rpc/mix.* ./apps/json_rpc/
COPY apps/metrix/mix.* ./apps/metrix/
COPY apps/proxy/mix.* ./apps/proxy/
COPY apps/storage/mix.* ./apps/storage/
COPY apps/web_api/mix.* ./apps/web_api/

RUN mix do deps.get, deps.compile

# This copies our app source code into the build container
COPY . .
RUN mix compile

RUN \
  mkdir -p /opt/built && \
  mix release ${APP_NAME} && \
  cp -R _build/${MIX_ENV}/rel/${APP_NAME} /opt/built


#######
#
# Running container
#
#######
FROM alpine:${ALPINE_VERSION}

# The name of your application/release (required)
ARG APP_NAME=${APP_NAME}
ARG PORT=4000
ARG DEPLOYMENT_WORKER_IMAGE=makerdao/testchain-deployment-worker:dev
# The environment to build with
ARG MIX_ENV=prod

# Expose prometheus port
EXPOSE 9568

# Expose Main API port
EXPOSE ${PORT}

WORKDIR /opt/app

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl \
      docker

ENV APP_NAME=${APP_NAME} \
    PORT=${PORT} \
    MIX_ENV=${MIX_ENV} \
    DEPLOYMENT_SERVICE_URL=http://testchain-deployment.local:5001/rpc \
    CHAINS_FRONT_URL=host.docker.internal \
    CHAINS_DB_PATH=/opt/chains \
    NATS_URL=nats.local \
    STACKS_DIR=/opt/stacks \
    SNAPSHOTS_DB_PATH="/opt/snapshots" \
    STACKS_FRONT_URL=http://localhost \
    RELEASE_COOKIE="W_cC]7^rUeVZc|}$UL{@&1sQwT3}p507mFlh<E=/f!cxWI}4gpQx7Yu{ZUaD0cuK" \
    RELEASE_NODE=staxx@staxx.local \
    DOCKER_DEV_MODE_ALLOWED=false \
    DEPLOYMENT_WORKER_IMAGE=${DEPLOYMENT_WORKER_IMAGE}

COPY --from=builder /opt/built/${APP_NAME} .
COPY ./apps/docker/priv/wrapper.sh /opt/app/apps/docker/priv/wrapper.sh

# RUN chown -R nobody: /opt/app
# USER nobody

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} start
