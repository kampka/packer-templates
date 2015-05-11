#!/bin/bash

set -e

echo "Running installation."

echo "I am $(whoami)"

pacman -Syy



DEVICE="/dev/sda"
[ -b $DEVICE ] || DEVICE="/dev/vda"
[ -b $DEVICE ] || {
    echo "Could not find root device. Exiting."
    exit 1
}

export DEVICE

echo "Preparing $DEVICE"


fdisk $DEVICE <<EOF
o
n
p
1

+100M
a
n
p
2


w
EOF

pacman -S --noconfirm btrfs-progs

echo "Formating ${DEVICE}1 with ext4"
mkfs.ext4 -L boot "${DEVICE}1"
echo "Formating ${DEVICE}2 with btrfs"
mkfs.btrfs -l 16k -L root "${DEVICE}2"

echo "Mounting harddrive to /mnt"
mount -o compress=lzo "${DEVICE}2" /mnt
mkdir -p /mnt/boot
mount "${DEVICE}1" /mnt/boot

echo "Debootstraping rootfs"
pacstrap /mnt base

echo "Generating fstab"

cat > /mnt/etc/fstab <<EOF
${DEVICE}1      /boot   ext4    defaults                0   1
${DEVICE}2      /       btrfs   defaults,compress=lzo   0   1
EOF

cat /etc/resolv.conf > /mnt/etc/resolv.conf

echo "Continuing in chroot"
cp /tmp/chroot.sh /mnt/chroot.sh
chmod a+x /mnt/chroot.sh
arch-chroot /mnt /chroot.sh
rm -f /mnt/chroot.sh

echo "No longer in chroot"

echo "Installing vagrant ssh key"

mkdir -p /mnt/root/.ssh
mv /tmp/vagrant.pub /mnt/root/.ssh/authorized_keys
chmod -R 600 /mnt/root/.ssh

echo "Unmounting chroot file systems"
umount -f /mnt/boot
umount -f /mnt

exit 0
