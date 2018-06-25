#!/usr/bin/env bash
set -xueo pipefail

RELEASE=$(lsb_release -sc)

GO_VERSION=${GO_VERSION:-}
OP_VERSION=${OP_VERSION:-}
DEP_VERSION=${DEP_VERSION:-}

add_gpg_keys() {
	curl -fsSL "${1}" | apt-key add -
}

add_apt_repo() {
	add-apt-repository "deb [arch=amd64] ${1}"
}

cd "$(mktemp -d -t 'packer-XXXXX')"

# gcloud
add_gpg_keys "https://packages.cloud.google.com/apt/doc/apt-key.gpg"
add_apt_repo "https://packages.cloud.google.com/apt cloud-sdk-\"${RELEASE}\" main"

# update the things
apt-get -qqy update

# install the things
apt-get -qqy install \
  google-cloud-sdk \
  kubectl

# 1password cli
curl -sLOJ https://cache.agilebits.com/dist/1P/op/pkg/v"${OP_VERSION}"/op_linux_amd64_v"${OP_VERSION}".zip
unzip op_linux_amd64_v"${OP_VERSION}".zip

# get le keys
for KEYSERVER in \
	ha.pool.sks-keyservers.net \
	hkp://p80.pool.sks-keyservers.net:80 \
	keyserver.ubuntu.com \
	hkp://keyserver.ubuntu.com:80 \
	pgp.mit.edu; do
	if gpg --keyserver "${KEYSERVER}" --recv-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22; then
		break;
	fi
done
gpg --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
gpg --verify op.sig op
mv -v op /usr/local/bin/op

# golang
curl -sSLOJ https://dl.google.com/go/go"${GO_VERSION}".linux-amd64.tar.gz
tar -xzf go"${GO_VERSION}".linux-amd64.tar.gz -C /usr/local

# dep
curl -sSLOJ https://github.com/golang/dep/releases/download/v"${DEP_VERSION}"/dep-linux-amd64
curl -sSLOJ https://github.com/golang/dep/releases/download/v"${DEP_VERSION}"/dep-linux-amd64.sha256
[ "$(sha256sum dep-linux-amd64 | awk '{print $1}')" == "$(awk '{print $1}' dep-linux-amd64.sha256)" ]
mv -v dep-linux-amd64 /usr/local/bin/dep
chmod +x /usr/local/bin/dep

# skaffold
curl -sSLOJ https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
mv -v skaffold-linux-amd64 /usr/local/bin/skaffold
chmod +x /usr/local/bin/skaffold
