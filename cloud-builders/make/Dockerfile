ARG GO_VERSION=1.18-alpine
FROM golang:$GO_VERSION

ARG JQ_VERSION=1.6
ARG CP_ASSETS_PATH=/workspace/pipeline_modules/assets/scripts

RUN apk --update add --no-cache curl git wget bash build-base && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apk/*

RUN curl -sLJO https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq

ENV PATH=$CP_ASSETS_PATH:$PATH

ENTRYPOINT ["make"]
