#!/bin/sh

set -e

echo "Configuring sshd"

apk update
apk add openssh

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

echo "root:packer" | chpasswd

/etc/init.d/sshd start

exit 0
