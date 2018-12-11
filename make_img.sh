#!/bin/sh

## make_img.sh ##

# Creates a zipped & partitioned image file for burning onto SD cards
# 256MB bootable FAT32L partition with official Alpine linux and lncm-box
# Make sure "parted", "dosfstools" and "zip" are installed

# Copyright © 2018 LNCM contributors

# This script, "make_img.sh" is under MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

VER=v0.3.0
ALP=alpine-rpi-3.8.1-armhf.tar.gz
IMG=lncm-box-${VER}.img
IOT=iotwifi.tar.gz
FIX=modloop-rpi2.tar.gz
CACHE=cache.tar.gz
MNT=/mnt/lncm

if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

# Todo: check for zip & unzip, mkfs.vfat, etc too
if command -v parted 2>&1 1>/dev/null; [ "$?" -ne "0" ]; then
  echo "'parted' package needs to be installed. If you're on a Debian-based system, you can install it with:"
  echo "	sudo apt install -y parted"
  exit 1
fi

echo "Building ${IMG}"
echo "Using ${ALP} as base distribution"

echo 'Generate fresh box.apkovl.tar.gz from source'
sh make_apkovl.sh

if ! [ -d lncm-workdir ]; then
  mkdir lncm-workdir
fi
cd lncm-workdir

if ! [ -f $ALP ]; then
  echo "${ALP} not found, fetching..."
  wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/${ALP}
fi
if ! [ -f $IOT ]; then
  echo "${IOT} not found, fetching..."
  wget https://github.com/lncm/pi-factory/releases/download/${VER}/${IOT}
fi
if ! [ -f $FIX ]; then
  echo "${FIX} not found, fetching..."
  wget https://github.com/lncm/pi-factory/releases/download/${VER}/${FIX}
fi
if ! [ -f $CACHE ]; then
  echo "${CACHE} not found, fetching..."
  wget https://github.com/lncm/pi-factory/releases/download/${VER}/${CACHE}
fi

echo "Create and mount 256MB image"
dd if=/dev/zero of=$IMG bs=1M count=256 && \
DEV=$(losetup -f) && \
losetup -f $IMG && \
echo "Create 256MB FAT32 partition and filesystem" && \
parted -s $DEV mklabel msdos mkpart p fat32 2048s 100% set 1 boot on && \
mkfs.vfat ${DEV}p1 -IF 32
if ! [ -d $MNT ]; then
  mkdir $MNT
fi
echo "Mount FAT partition"
mount ${DEV}p1 $MNT
echo "Extract alpine distribution"
tar -xzf $ALP -C ${MNT}/ --no-same-owner
echo "Extract iotwifi container"
tar -xzf $IOT -C ${MNT}/ --no-same-owner
echo "Extract cache dir for docker and avahi"
tar -xzf $CACHE -C ${MNT}/ --no-same-owner
echo "Patch RPi3 WiFi"
tar -xzf $FIX -C ${MNT}/boot/ --no-same-owner
echo "Copy latest box.apkovl tarball"
cp ../box.apkovl.tar.gz ${MNT}
echo "Flush writes to disk"
sync
echo "Unmount"
umount $MNT
losetup -d ${DEV}
echo "Compress img as zip"
zip -r ${IMG}.zip $IMG
echo -e "Done!\nYou may flash your ${IMG}.zip using Etcher or dd the ${IMG}"