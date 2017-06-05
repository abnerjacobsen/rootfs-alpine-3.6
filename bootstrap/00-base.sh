#!/usr/bin/with-contenv sh

# This folder is in $PATH by default but isn't created
mkdir -p /usr/local/sbin \

# Install minimal packages
&& apk add --update --no-cache ca-certificates wget ssmtp 'su-exec>=0.2' \

# Install s6 overlay
&& wget https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz --no-check-certificate -O /tmp/s6-overlay.tar.gz \
&& tar xvfz /tmp/s6-overlay.tar.gz -C / \
&& rm -f /tmp/s6-overlay.tar.gz \

# Install gomplate
&& wget https://github.com/hairyhenderson/gomplate/releases/download/v1.6.0/gomplate_linux-amd64-slim -O /usr/bin/gomplate \
&& chmod 755 /usr/bin/gomplate

