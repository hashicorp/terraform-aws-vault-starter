#!/usr/bin/env bash
set -euxo pipefail

vault_download="https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
vault_checksum_file="https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_SHA256SUMS"
vault_checksum_sig="${vault_checksum_file}.sig"
vault_filename="vault_${vault_version}_linux_amd64.zip"

# Constant
readonly vault_gpg_key="-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBFMORM0BCADBRyKO1MhCirazOSVwcfTr1xUxjPvfxD3hjUwHtjsOy/bT6p9f
W2mRPfwnq2JB5As+paL3UGDsSRDnK9KAxQb0NNF4+eVhr/EJ18s3wwXXDMjpIifq
fIm2WyH3G+aRLTLPIpscUNKDyxFOUbsmgXAmJ46Re1fn8uKxKRHbfa39aeuEYWFA
3drdL1WoUngvED7f+RnKBK2G6ZEpO+LDovQk19xGjiMTtPJrjMjZJ3QXqPvx5wca
KSZLr4lMTuoTI/ZXyZy5bD4tShiZz6KcyX27cD70q2iRcEZ0poLKHyEIDAi3TM5k
SwbbWBFd5RNPOR0qzrb/0p9ksKK48IIfH2FvABEBAAG0K0hhc2hpQ29ycCBTZWN1
cml0eSA8c2VjdXJpdHlAaGFzaGljb3JwLmNvbT6JAU4EEwEKADgWIQSRpuf4XQXG
VjC+8YlRhS2HNI/8TAUCXn0BIQIbAwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAK
CRBRhS2HNI/8TJITCACT2Zu2l8Jo/YLQMs+iYsC3gn5qJE/qf60VWpOnP0LG24rj
k3j4ET5P2ow/o9lQNCM/fJrEB2CwhnlvbrLbNBbt2e35QVWvvxwFZwVcoBQXTXdT
+G2cKS2Snc0bhNF7jcPX1zau8gxLurxQBaRdoL38XQ41aKfdOjEico4ZxQYSrOoC
RbF6FODXj+ZL8CzJFa2Sd0rHAROHoF7WhKOvTrg1u8JvHrSgvLYGBHQZUV23cmXH
yvzITl5jFzORf9TUdSv8tnuAnNsOV4vOA6lj61Z3/0Vgor+ZByfiznonPHQtKYtY
kac1M/Dq2xZYiSf0tDFywgUDIF/IyS348wKmnDGjuQENBFMORM0BCADWj1GNOP4O
wJmJDjI2gmeok6fYQeUbI/+Hnv5Z/cAK80Tvft3noy1oedxaDdazvrLu7YlyQOWA
M1curbqJa6ozPAwc7T8XSwWxIuFfo9rStHQE3QUARxIdziQKTtlAbXI2mQU99c6x
vSueQ/gq3ICFRBwCmPAm+JCwZG+cDLJJ/g6wEilNATSFdakbMX4lHUB2X0qradNO
J66pdZWxTCxRLomPBWa5JEPanbosaJk0+n9+P6ImPiWpt8wiu0Qzfzo7loXiDxo/
0G8fSbjYsIF+skY+zhNbY1MenfIPctB9X5iyW291mWW7rhhZyuqqxN2xnmPPgFmi
QGd+8KVodadHABEBAAGJATwEGAECACYCGwwWIQSRpuf4XQXGVjC+8YlRhS2HNI/8
TAUCXn0BRAUJEvOKdwAKCRBRhS2HNI/8TEzUB/9pEHVwtTxL8+VRq559Q0tPOIOb
h3b+GroZRQGq/tcQDVbYOO6cyRMR9IohVJk0b9wnnUHoZpoA4H79UUfIB4sZngma
enL/9magP1uAHxPxEa5i/yYqR0MYfz4+PGdvqyj91NrkZm3WIpwzqW/KZp8YnD77
VzGVodT8xqAoHW+bHiza9Jmm9Rkf5/0i0JY7GXoJgk4QBG/Fcp0OR5NUWxN3PEM0
dpeiU4GI5wOz5RAIOvSv7u1h0ZxMnJG4B4MKniIAr4yD7WYYZh/VxEPeiS/E1CVx
qHV5VVCoEIoYVHIuFIyFu1lIcei53VD6V690rmn0bp4A5hs+kErhThvkok3c
=+mCN
-----END PGP PUBLIC KEY BLOCK-----"

echo "Installing jq"
sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /bin/jq

echo "Configuring system time"
sudo timedatectl set-timezone UTC

echo "Verify checksum of Vault binary"
verify_checksum() {
  cd /tmp && {
    curl -O "${vault_download}"
    curl -O "${vault_checksum_file}"
    curl -O "${vault_checksum_sig}"

    echo -e "${vault_gpg_key}" | gpg --import -
    gpg --batch --verify "vault_${vault_version}_SHA256SUMS.sig" "vault_${vault_version}_SHA256SUMS"
    grep "${vault_filename}" "vault_${vault_version}_SHA256SUMS" | sha256sum -c
    mv "${vault_filename}" "vault.zip"
  }
  echo "Vault binary checksum has been successfully verified"
  echo "Proceeding with installation"
}

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

verify_checksum
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
