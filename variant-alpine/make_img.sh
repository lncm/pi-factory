#!/bin/bash

# Creates a zipped & partitioned image file for burning onto SD cards
# 256MB bootable FAT32L partition with official Alpine linux and lncm box
# Make sure "parted", "dosfstools" and "zip" are installed

mkdir lncm-workdir
cd lncm-workdir
ALP=alpine-rpi-3.8.1-armhf.tar.gz
BOX=lncm-box-v0.2.1.tar.gz
IMG=lncm-box-v0.2.1.img
MNT=/mnt/lncm
wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/${ALP}
wget https://github.com/lncm/pi-factory/releases/download/v0.2.1/${BOX}
dd if=/dev/zero of=$IMG bs=1M count=256
DEV=$(losetup -f --show $IMG)
parted -s $DEV mklabel msdos mkpart p fat32 2048s 100% set 1 boot on
parted -s $DEV print
mkfs.vfat ${DEV}p1 -IF 32
mkdir $MNT
mount ${DEV}p1 $MNT
tar -xzf $ALP -C ${MNT}/ --no-same-owner
tar -xzf $BOX -C ${MNT}/ --no-same-owner
sync
umount $MNT
losetup -d ${DEV}
zip -r ${IMG}.zip $IMG
