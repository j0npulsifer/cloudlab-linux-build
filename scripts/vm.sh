#!/usr/bin/env bash
set -xeuo pipefail

# this script is for vm based deployments
# aka it installs daemons like datadog and falco

RELEASE=$(lsb_release -sc)

add_gpg_keys() {
  curl -fsSL ${1} | apt-key add -
}

add_apt_repo() {
  add-apt-repository "deb [arch=amd64] ${1}"
}

# datadog
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 382E94DE
add_apt_repo "https://apt.datadoghq.com/ stable 6"

# docker
add_gpg_keys "https://download.docker.com/linux/ubuntu/gpg"
add_apt_repo "https://download.docker.com/linux/ubuntu ${RELEASE} stable"

# falco
add_gpg_keys "https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public"
add_apt_repo 'http://download.draios.com/stable/deb stable-$(ARCH)/'

# update the things
apt-get -qqy update

# install the things
apt-get -qqy install \
  datadog-agent \
  docker-ce \
  falco \
  linux-headers-$(uname -r)
