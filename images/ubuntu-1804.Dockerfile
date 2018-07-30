FROM ubuntu:bionic
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
COPY etc/ssh/sshd_config /etc/ssh/

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
