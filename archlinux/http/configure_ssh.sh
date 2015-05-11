#!/bin/bash

set -e

echo "Configuring sshd"

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

echo "root:packer" | sudo chpasswd

systemctl restart sshd

exit 0
