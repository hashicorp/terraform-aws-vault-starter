#!/usr/bin/env bash
set -euxo pipefail

echo "Installing updates and pre-requisites...."
sudo yum -y check-update || true
sudo yum -y update
sudo yum install -q -y wget unzip bind-utils \
  ntp ca-certificates vim-enhanced

if ! systemctl is-enabled --quiet ntpd.service; then
  sudo systemctl enable ntpd.service
fi

if systemctl is-enabled --quiet firewalld; then
  sudo systemctl disable firewalld
fi

curl --silent -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
sudo pip install awscli
echo "Adding Vault system user"
  # RHEL user setup
for _user in vault; do
  sudo /usr/sbin/groupadd --force --system ${_user}
  if ! getent passwd ${_user} >/dev/null ; then
    sudo /usr/sbin/adduser \
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
