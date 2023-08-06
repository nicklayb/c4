# STEP 1 - Build release compiler container
FROM elixir:1.14-alpine AS builder

ENV APP_NAME=c4 \
    APP_VERSION=0.1.0 \
    MIX_ENV=prod

WORKDIR /c4

# Install build requirements
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache openssl-dev make build-base gcc git

RUN mix local.rebar --force && \
    mix local.hex --force

# Compile dependencies and application
COPY . .
RUN mix deps.get --only ${MIX_ENV}
RUN mix compile

# Create a release
RUN mkdir -p /opt/build && \
    mix release && \
    cp -r _build/${MIX_ENV}/rel /opt/build

# STEP 2 - Build application container
FROM alpine:3.16

ARG APP_NAME
ENV APP_NAME=${APP_NAME}

ENV ROOT_FOLDER=/opt

# Update kernel and install runtime dependencies
RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add bash openssl libstdc++ libgcc

WORKDIR ${ROOT_FOLDER}

# Copy the OTP binary from the build step
COPY --from=builder /opt/build .

RUN ls .

COPY dockerfiles/entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/entrypoint.sh
RUN mkdir ${ROOT_FOLDER}/logs

# Create a non-root user
RUN adduser -D c4 && \
    chown -R c4: ${ROOT_FOLDER}

USER c4

ENTRYPOINT ["entrypoint.sh"]
CMD ["start"]
