FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    HOME=/home/coder \
    USER=coder \
    SHELL=/bin/bash

COPY dockerfiles/scripts/base-packages.sh /tmp/base-packages.sh
RUN sh /tmp/base-packages.sh

COPY dockerfiles/scripts/desktop-packages.sh /tmp/desktop-packages.sh
RUN sh /tmp/desktop-packages.sh

COPY dockerfiles/scripts/xfce-packages.sh /tmp/xfce-packages.sh
RUN sh /tmp/xfce-packages.sh

COPY dockerfiles/scripts/install-code-server.sh /tmp/install-code-server.sh
RUN sh /tmp/install-code-server.sh

COPY dockerfiles/scripts/setup-coder-user.sh /tmp/setup-coder-user.sh
RUN sh /tmp/setup-coder-user.sh

USER coder
WORKDIR /home/coder
