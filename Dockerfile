FROM golang:alpine as build
MAINTAINER timo.taskinen@vincit.fi
LABEL maintainer "timo.taskinen@vincit.fi"
ENV LOGSPOUT_VERSION=3.2.6
ENV LOGSPOUT_DOWNLOAD_SHA256=564219534d00a92e4e96a25abf00dbf26ea8608d58182d353e6d9154119977e3
RUN mkdir -p /go/src
WORKDIR /go/src
VOLUME /mnt/routes
EXPOSE 80

RUN apk --no-cache add --update curl git gcc musl-dev go build-base git mercurial ca-certificates
RUN curl -fSL -o logspout_v${LOGSPOUT_VERSION}.tgz "https://github.com/gliderlabs/logspout/releases/download/v${LOGSPOUT_VERSION}/logspout_v${LOGSPOUT_VERSION}.tgz" \
    && echo "$LOGSPOUT_DOWNLOAD_SHA256 logspout_v${LOGSPOUT_VERSION}.tgz" | sha256sum -c - \
    && tar -zxvf logspout_v${LOGSPOUT_VERSION}.tgz \
    && rm logspout_v${LOGSPOUT_VERSION}.tgz \
    && mkdir -p /go/src/github.com/gliderlabs/ \
    && mv logspout-${LOGSPOUT_VERSION} /go/src/github.com/gliderlabs/logspout

WORKDIR /go/src/github.com/gliderlabs/logspout
RUN echo 'import ( _ "github.com/gliderlabs/logspout/adapters/raw" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/adapters/syslog" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/httpstream" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/routesapi" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/transports/tcp" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/transports/udp" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/transports/tls" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/healthcheck" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/gliderlabs/logspout/adapters/multiline" )' >> /go/src/github.com/gliderlabs/logspout/modules.go \
    && echo 'import ( _ "github.com/karlvr/logspout-gelf" )' >> /go/src/github.com/gliderlabs/logspout/modules.go



RUN go get -d -v ./...
RUN go build -v -ldflags "-X main.Version=$(cat VERSION)" -o ./bin/logspout

FROM alpine:latest
COPY --from=build /go/src/github.com/gliderlabs/logspout/bin/logspout /go/bin/logspout
ENTRYPOINT ["/go/bin/logspout"]
