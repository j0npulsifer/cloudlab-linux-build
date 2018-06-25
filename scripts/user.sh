#!/usr/bin/env bash
set -xueo pipefail

LINUX_USER="${LINUX_USER:-}"
LINUX_UUID="${LINUX_UUID:-}"
GITHUB_USER="${GITHUB_USER:-}"
AUTHORIZED_KEYS="/var/ssh/${LINUX_USER}/authorized_keys"

# user
adduser \
  --disabled-password \
  --GECOS '' \
  --uid "${LINUX_UUID}" \
  "${LINUX_USER}"

# sudo
echo "${LINUX_USER}	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# ssh authorized keys
mkdir -vp /var/ssh/"${LINUX_USER}"
curl -sOJ https://github.com/"${GITHUB_USER}".keys
mv -v "${GITHUB_USER}".keys "${AUTHORIZED_KEYS}"
chown "${LINUX_USER}":"${LINUX_USER}" "${AUTHORIZED_KEYS}"
chmod 644 "${AUTHORIZED_KEYS}"

# extra groups
usermod -aG docker "${LINUX_USER}"
