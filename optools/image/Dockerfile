FROM golang:1.24-alpine AS builder

ARG GITHUB_TOKEN

RUN if [ -z "$GITHUB_TOKEN" ]; then \
        echo "Error: GITHUB_TOKEN must be specified" && exit 1; \
    fi

RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev

RUN go env -w GOPROXY=https://proxy.golang.org,direct

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/matrixorigin/mo-backup.git /build/mo-backup && \
    cd /build/mo-backup && \
    make && \
    cp mo_br /mo_br

RUN git clone https://x-access-token:${GITHUB_TOKEN}@github.com/matrixorigin/mo_dump.git /build/mo_dump && \
    cd /build/mo_dump && \
    make && \
    cp mo-dump /mo-dump

FROM alpine:3.18

ARG TARGETARCH

RUN apk add --no-cache \
    bash \
    curl \
    mysql-client

RUN if [ "$TARGETARCH" = "arm64" ]; then \
      curl https://dl.min.io/client/mc/release/linux-arm64/mc -o /usr/local/bin/mc; \
    else \
      curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc; \
    fi; \
    chmod +x /usr/local/bin/mc

COPY --from=builder /mo_br /mo_br
COPY --from=builder /mo-dump /mo-dump
RUN chmod +x /mo_br /mo-dump

RUN mkdir /mo_ctl
COPY . /mo_ctl/

ENTRYPOINT ["/mo_ctl/mo_ctl.sh"]
