#!/bin/bash

set -e

echo "Configuring sshd"

apt-get update
apt-get install -qy --no-install-recommends openssh-server

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

echo "root:packer" | sudo chpasswd

service ssh restart

exit 0
