FROM --platform=$BUILDPLATFORM golang:1.15-buster AS src

ARG VERSION=v2.0.0
ARG BUILDPLATFORM

RUN git clone https://github.com/kubernetes-csi/node-driver-registrar.git /go/src/node-driver-registrar

WORKDIR /go/src/node-driver-registrar

RUN git checkout ${VERSION}

FROM --platform=$BUILDPLATFORM src AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -a -installsuffix cgo -ldflags '-X main.version=$(REV) -extldflags "-static"' ./cmd/csi-node-driver-registrar


FROM gcr.io/distroless/static

COPY --from=builder /go/src/node-driver-registrar/csi-node-driver-registrar /bin/csi-node-driver-registrar

USER 1234:1234

ENTRYPOINT ["/bin/csi-node-driver-registrar"]

