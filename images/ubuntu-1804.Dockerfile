FROM gcr.io/trusted-builds/ubuntu-1804-base@sha256:733a42ca998c8ab61a678c294969c9087ecee9376b0eef12687f06eb7b040cb9
LABEL maintainer=jonathan@pulsifer.ca \
      ca.pulsifer.os=linux \
      ca.pulsifer.distro=ubuntu \
      ca.pulsifer.codename=bionic \
      ca.pulsifer.release=18.04

WORKDIR /tmp/build
COPY scripts scripts
RUN chmod +x ./scripts/*.sh \
 && ./scripts/base.sh \
 && ./scripts/packages.sh \
 && ./scripts/user.sh

COPY etc/environment /etc/
