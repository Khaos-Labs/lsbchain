# Simple usage with a mounted data directory:
# > docker build -t lsbchain .
# > docker run -it -p 36657:36657 -p 36656:36656 -v ~/.lsbchaind:/root/.lsbchaind -v ~/.lsbchaincli:/root/.lsbchaincli lsbchain lsbchaind init mynode
# > docker run -it -p 36657:36657 -p 36656:36656 -v ~/.lsbchaind:/root/.lsbchaind -v ~/.lsbchaincli:/root/.lsbchaincli lsbchain lsbchaind start
FROM golang:alpine AS build-env

# Install minimum necessary dependencies, remove packages
RUN apk add --no-cache curl make git libc-dev bash gcc linux-headers eudev-dev

# Set working directory for the build
WORKDIR /go/src/github.com/Khaos-Labs/lsbchain

# Add source files
COPY . .

# Build LSBChain
RUN GOPROXY=http://goproxy.cn make install

# Final image
FROM alpine:edge

WORKDIR /root

# Copy over binaries from the build-env
COPY --from=build-env /go/bin/lsbchaind /usr/bin/lsbchaind
COPY --from=build-env /go/bin/lsbchaincli /usr/bin/lsbchaincli

# Run okexchaind by default, omit entrypoint to ease using container with lsbchaincli
CMD ["lsbchaind"]