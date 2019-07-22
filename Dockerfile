# The version of Alpine to use for the final image
ARG ALPINE_VERSION=3.9

FROM elixir:1.9.0-alpine as builder

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG APP_NAME=testchain_backendgateway
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
COPY apps/proxy/mix.* ./apps/proxy/
COPY apps/stacks/mix.* ./apps/stacks/
COPY apps/web_api/mix.* ./apps/web_api/

RUN mix do deps.get, deps.compile

# This copies our app source code into the build container
COPY . .
RUN mix compile

RUN \
  mkdir -p /opt/built && \
  mix release && \
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
# The environment to build with
ARG MIX_ENV=prod

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
    STACKS_FRONT_URL=http://localhost \
    RELEASE_COOKIE="W_cC]7^rUeVZc|}$UL{@&1sQwT3}p507mFlh<E=/f!cxWI}4gpQx7Yu{ZUaD0cuK" \
    DOCKER_DEV_MODE_ALLOWED=false

COPY --from=builder /opt/built/${APP_NAME} .
COPY ./apps/docker/priv/wrapper.sh /opt/app/apps/docker/priv/wrapper.sh

# RUN chown -R nobody: /opt/app
# USER nobody

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} start
