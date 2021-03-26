FROM golang:stretch as build-env

# Install minimum necessary dependencies
ENV PACKAGES curl make git libc-dev bash gcc
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y $PACKAGES

# Set working directory for the build
WORKDIR /go/src/github.com/Khaos-Labs/lsbchain

# Add source files
COPY . .

# build Lsbchain
RUN make build-lsbchain-linux

# Final image
FROM golang:1.14 as final

WORKDIR /

RUN apt-get update

# Copy over binaries from the build-env
COPY --from=build-env /go/src/github.com/Khaos-Labs/lsbchain/build/lsbchaind /usr/bin/lsbchaind
COPY --from=build-env /go/src/github.com/Khaos-Labs/lsbchain/build/lsbchaincli /usr/bin/lsbchaincli
COPY --from=build-env /go/src/github.com/Khaos-Labs/lsbchain/scripts/start.sh /

EXPOSE 26656 26657 1317 8545 8546

# Run lsbchaind by default, omit entrypoint to ease using container with lsbchaincli
ENTRYPOINT ["/bin/bash", "-c"]