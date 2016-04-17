#!/bin/bash

set -e

DEVICE=${DEVICE:-/dev/sda}
[ -b $DEVICE ] || DEVICE="/dev/vda"
[ -b $DEVICE ] || {
    echo "Could not find root device. Exiting."
    exit 1
}

echo "Running in chroot"
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_FRONTEND=noninteractive

echo "Setting hostname"
echo "trusty" > /etc/hostname

echo "Setting local time zone"
apt-get -qy install locales
ln -vsf /usr/share/zoneinfo/UTC /etc/localtime

echo "Generating locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

echo 'LANG=de_DE.utf8' > /etc/locale.conf

cat > /etc/default/keyboard <<EOF
XKBMODEL=”pc105″
XKBLAYOUT=”de”
XKBVARIANT=”nodeadkeys”
XKBOPTIONS=””
EOF

echo "Installing sshd"
apt-get -yq install openssh-server rsync sudo

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

echo "Installing kernel and grub"

apt-get -yq install linux-image-generic grub-pc

echo "Installing grub on $DEVICE"
grub-install --force $DEVICE
update-grub2


echo "Setting up root user"
echo "root:packer" | chpasswd

echo "Configuring network interfaces"

apt-get -yq install net-tools isc-dhcp-client

mkdir -p /etc/network/interfaces.d
cat > /etc/network/interfaces.d/loopback <<EOF
# The loopback network interface
auto lo
iface lo inet loopback
EOF

cat > /etc/network/interfaces.d/eth0 <<EOF
# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF

echo "Create vagrant folder /vagrant"
mkdir -p /vagrant

exit 0
