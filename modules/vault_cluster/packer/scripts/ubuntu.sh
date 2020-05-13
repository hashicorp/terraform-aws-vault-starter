#!/usr/bin/env bash
set -euxo pipefail

sudo apt -y update
sudo apt -y upgrade
sudo apt install -y wget unzip bind9-dnsutils ntp \
    ca-certificates vim awscli

if ! systemctl is-enabled --quiet ntp.service; then
  sudo systemctl enable ntp.service
fi

if systemctl is-enabled --quiet ufw; then
  sudo systemctl disable ufw
fi

# Ubuntu user setup
for _user in vault; do
  sudo /usr/sbin/groupadd --force --system ${_user}
  if ! getent passwd ${_user} >/dev/null ; then
    sudo /usr/sbin/useradd \
      --system \
      --gid ${_user} \
      --home /srv/${_user} \
      --no-create-home \
      --comment "${_user} account" \
      --shell /bin/false \
      ${_user}  >/dev/null
  fi
done

echo 'output: { all: "| tee -a /var/log/cloud-init-output.log" }' | sudo tee -a /etc/cloud/cloud.cfg.d/05_logging.cfg
