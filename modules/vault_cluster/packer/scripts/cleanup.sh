#!/usr/bin/env bash
set -euxo pipefail

echo "Running"

echo "Cleanup AWS install artifacts"
sudo rm -rf /var/lib/cloud/instances/*
sudo rm -f /root/.ssh/authorized_keys
sudo rm -f /etc/ssh/ssh_host_*
#sudo rm -rf /tmp/*
history -c

echo "Complete"
