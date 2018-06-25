FROM ubuntu:bionic
LABEL maintainer jonathan@pulsifer.ca

WORKDIR /tmp/build
COPY scripts scripts
RUN ls -l
RUN ./scripts/base.sh
RUN ./scripts/packages.sh
RUN ./scripts/user.sh

COPY etc/environment /etc/
COPY etc/ssh/sshd_config /etc/ssh/

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
