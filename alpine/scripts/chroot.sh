#!/bin/sh

set -e
set -x
set -u

[ -z "$DEVICE" ] && DEVICE="/dev/sda"

[ -b $DEVICE ] || DEVICE="/dev/vda"
[ -b $DEVICE ] || {
    echo "Could not find root device. Exiting."
    exit 1
}

echo "Running in chroot"

echo "Setting hostname"
echo "alpine" > /etc/hostname

apk update
apk upgrade

echo "Setting local time zone"
ln -vsf /usr/share/zoneinfo/UTC /etc/localtime

echo "Installing sshd"
apk add openssh rsync

sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*//g" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config

echo "Installing kernel and syslinux"

apk add linux-grsec syslinux btrfs-progs mkinitfs

sed -i 's/"$/ btrfs network virtio"/g' /etc/mkinitfs/mkinitfs.conf
echo "kernel/drivers/net/virtio_net*" >> /etc/mkinitfs/features.d/virtio.modules

sed -i 's/modules=.*/modules=btrfs,ext3,ext4/g' /etc/update-extlinux.conf

echo "Installing syslinux on $DEVICE"
mkdir -p /boot


KERNEL_VERSION="$(ls -A /lib/modules/ | tail -1)"
mkinitfs "$KERNEL_VERSION"

cat >/boot/extlinux.conf <<EOF
timeout 20
prompt 1
default grsec
label grsec
  kernel /boot/vmlinuz-grsec
  append initrd=/boot/initramfs-grsec root=${DEVICE}2 modules=ext3,ext4,btrfs
EOF

echo "Setting up root user"
echo "root:packer" | chpasswd


echo "Configuring network interfaces"

apk add dhcp

cat > /etc/network/interfaces <<EOF
# The loopback network interface
auto lo
iface lo inet loopback
EOF

cat >> /etc/network/interfaces <<EOF
# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF

echo "#VAGRANT-BEGIN #" >> /etc/network/interfaces


rc-update -q add networking boot
rc-update -q add urandom boot
rc-update -q add acpid
rc-update -q add sshd default
rc-update -q add hostname boot

echo "Create vagrant folder /vagrant"
mkdir -p /vagrant

exit 0
