#!/usr/bin/env bash
set -euxo pipefail

echo "Installing jq"
sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /bin/jq

echo "Configuring system time"
sudo timedatectl set-timezone UTC

echo "Installing Vault"
install_from_zip() {
  cd /tmp && {
    unzip -qq "${1}.zip"
    sudo mv "${1}" "/usr/local/bin/${1}"
    sudo chmod +x "/usr/local/bin/${1}"
    rm -rf "${1}.zip"
  }
}

echo "Configuring HashiCorp directories"
directory_setup() {
  # create and manage permissions on directories
  sudo mkdir -pm 0755 /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chown -R ${2}:${2} /etc/${1}.d /opt/${1}/data /opt/${1}/tls
}

install_from_zip vault
directory_setup vault vault


echo "Copy systemd services"

systemd_files() {
  sudo cp /tmp/files/$1 /etc/systemd/system
  sudo chmod 0664 /etc/systemd/system/$1
}

systemd_files vault.service

echo "Setup Vault profile"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
PROFILE