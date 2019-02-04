FROM gcr.io/trusted-builds/ubuntu-1804-base
LABEL maintainer=jonathan@pulsifer.ca \
      ca.lolwtf.os=linux \
      ca.lolwtf.distro=ubuntu \
      ca.lolwtf.codename=bionic \
      ca.lolwtf.release=18.04

ENV GO_VERSION=${GO_VERSION:-1.11.5}
ENV GO_CHECKSUM=${GO_CHECKSUM:-ff54aafedff961eb94792487e827515da683d61a5f9482f668008832631e5d25}

WORKDIR /tmp/build

RUN rm /etc/apt/apt.conf.d/docker-no-languages
RUN apt-get -qqy update && apt-get -qqy upgrade && \
    apt-get -qqy install \
      apt-transport-https \
      ca-certificates \
      curl \
      lsb-release \
      software-properties-common \
      bash-completion \
      cowsay \
      dnsutils \
      figlet \
      fortune \
      gawk \
      gcc \
      git \
      inetutils-traceroute \
      iputils-ping \
      iputils-tracepath \
      jq \
      lolcat \
      make \
      man \
      netcat \
      nmap \
      openssh-client \
      openssh-server \
      python-dev \
      python-pip \
      rsync \
      shellcheck \
      sudo \
      telnet \
      tmux \
      unzip \
      vim \
      wget

# golang
ADD https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz .
RUN echo "${GO_CHECKSUM} *go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum -c - && \
    tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local/

# gcloud
ADD https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz .
RUN tar -xzf google-cloud-sdk.tar.gz -C /usr/local/ && \
    /usr/local/google-cloud-sdk/install.sh --quiet --additional-components alpha beta

# set up ssh
COPY etc/ssh/sshd_config /etc/ssh/sshd_config
COPY etc/environment /etc/environment
RUN mkdir -p /run/sshd

# add and run scripts
COPY scripts scripts
RUN chmod +x ./scripts/*.sh \
 && ./scripts/user.sh
