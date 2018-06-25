#!/usr/bin/env bash
set -xeuo pipefail

DEBIAN_FRONTEND=noninteractive
LANG=${LANG:-en_US.UTF-8}

# root test
(($(id -u) == 0)) || { echo 'please run as root'; exit 1; }

apt-get -qqy clean
apt-get -qqy autoremove --purge
apt-get -qqy update
apt-get -qqy upgrade

# locales
apt-get -qqy install locales language-pack-en
locale-gen ${LANG}
update-locale ${LANG}

# prereqs
apt-get -qqy install \
  apt-transport-https \
  bash-completion \
  ca-certificates \
  cowsay \
  curl \
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
  lsb-release \
  make \
  man \
  netcat \
  nmap \
  openssh-client \
  openssh-server \
  python-dev \
  python-pip \
  rsync \
  software-properties-common \
  sudo \
  telnet \
  tmux \
  unzip \
  vim \
  wget

# pip things
pip install -U crcmod
pip install -U mdv

# ssh
mkdir -vp /var/run/sshd
