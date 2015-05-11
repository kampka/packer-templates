#!/bin/bash

set -e

echo "Running installation."

echo "I am $(whoami)"

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

apt-get -y install btrfs-tools debootstrap

echo "Formating ${DEVICE}1 with ext4"
mkfs.ext4 -L boot "${DEVICE}1"
echo "Formating ${DEVICE}2 with btrfs"
mkfs.btrfs -l 16k -L root "${DEVICE}2"

echo "Mounting harddrive to /mnt"
mount -o compress=lzo "${DEVICE}2" /mnt
mkdir -p /mnt/boot
mount "${DEVICE}1" /mnt/boot

echo "Debootstraping rootfs"
debootstrap --variant=minbase --arch=amd64 jessie /mnt

echo "Mounting chroot file systems"
mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts none /mnt/dev/pts

echo "Generating fstab"

cat > /mnt/etc/fstab <<EOF
${DEVICE}1      /boot   ext4    defaults                0   1
${DEVICE}2      /       btrfs   defaults,compress=lzo   0   1
EOF

cat /etc/resolv.conf > /mnt/etc/resolv.conf

echo "Continuing in chroot"
cp /tmp/chroot.sh /mnt/tmp/chroot.sh
chroot /mnt /bin/bash /tmp/chroot.sh

echo "No longer in chroot"

echo "Installing vagrant ssh key"

mkdir -p /mnt/root/.ssh
mv /tmp/vagrant.pub /mnt/root/.ssh/authorized_keys
chmod -R 600 /mnt/root/.ssh

echo "Unmounting chroot file systems"
umount -f /mnt/dev/pts
umount -f /mnt/dev
umount -f /mnt/sys
umount -f /mnt/proc
umount -f /mnt/boot
umount -f /mnt

exit 0
