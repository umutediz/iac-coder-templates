FROM coder-image-cache.coder.svc.cluster.local:5000/ubuntu-22.04-cli:latest

USER root

COPY dockerfiles/scripts/desktop-packages.sh /tmp/desktop-packages.sh
RUN sh /tmp/desktop-packages.sh

COPY dockerfiles/scripts/xfce-packages.sh /tmp/xfce-packages.sh
RUN sh /tmp/xfce-packages.sh

USER coder
WORKDIR /home/coder
