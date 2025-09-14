# syntax=docker/dockerfile:1

FROM scratch
COPY --from=qemux/qemu-arm:7.12 / /

ARG TARGETARCH
ARG VERSION_ARG="0.00"
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        samba \
        wimtools \
        dos2unix \
        cabextract \
        libxml2-utils \
        libarchive-tools \
        netcat-openbsd && \
    wget "https://github.com/gershnik/wsdd-native/releases/download/v1.21/wsddn_1.21_${TARGETARCH}.deb" -O /tmp/wsddn.deb -q && \
    dpkg -i /tmp/wsddn.deb && \
    apt-get clean && \
    echo "$VERSION_ARG" > /run/version && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

ADD --chmod=755 https://raw.githubusercontent.com/dockur/windows/refs/heads/master/src/mido.sh /run/
ADD --chmod=755 https://raw.githubusercontent.com/dockur/windows/refs/heads/master/src/power.sh /run/
ADD --chmod=755 https://raw.githubusercontent.com/dockur/windows/refs/heads/master/src/samba.sh /run/
ADD --chmod=755 https://raw.githubusercontent.com/dockur/windows/refs/heads/master/src/install.sh /run/

ADD --chmod=664 https://github.com/qemus/virtiso-arm/releases/download/v0.1.285-1/virtio-win-0.1.285.tar.xz /var/drivers.txz

VOLUME /storage
EXPOSE 3389 8006

ENV VERSION="11"
ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISK_SIZE="64G"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
