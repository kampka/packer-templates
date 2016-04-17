#!/bin/sh

set -e
set -x
set -u

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
1
n
p
2


w
EOF

ALPINE_MIRROR="http://dl-3.alpinelinux.org/alpine/latest-stable/main"
echo "$ALPINE_MIRROR" > /etc/apk/repositories
apk update
apk add btrfs-progs e2fsprogs

echo "Formating ${DEVICE}1 with ext4"
mkfs.ext4 -L boot "${DEVICE}1"
echo "Formating ${DEVICE}2 with btrfs"
mkfs.btrfs -l 16k -L root "${DEVICE}2"

mkdir -p /mnt

echo "Mounting harddrive to /mnt"
mount -t btrfs "${DEVICE}2" /mnt -o compress=lzo,suid
mkdir -p /mnt/boot
mount -t ext4 "${DEVICE}1" /mnt/boot

echo "Initializing apline rootfs"
apk -X "$ALPINE_MIRROR" -U --root "/mnt" --keys-dir /etc/apk/keys --initdb add alpine-base tzdata sudo
cp /etc/apk/repositories /mnt/etc/apk

echo "Mounting chroot file systems"
mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts none /mnt/dev/pts

echo "Generating fstab"

cat > /mnt/etc/fstab <<EOF
${DEVICE}1      /boot   ext4    defaults                0   1
${DEVICE}2      /       btrfs   defaults                0   1
EOF

cat /etc/resolv.conf > /mnt/etc/resolv.conf
echo "$ALPINE_MIRROR" > /mnt/etc/apk/repositories

echo "Continuing in chroot"
cp /tmp/chroot.sh /mnt/tmp/chroot.sh
chroot /mnt /bin/sh /tmp/chroot.sh

echo "No longer in chroot"
apk add syslinux
cp /mnt/etc/update-extlinux.conf /etc
extlinux -i /mnt/boot

cat /usr/share/syslinux/mbr.bin > ${DEVICE}

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
