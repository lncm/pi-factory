#!/bin/sh

## make_img.sh ##

# Creates a zipped & partitioned image file for burning onto SD cards
# 256MB bootable FAT32L partition with official Alpine linux and lncm-box
# Make sure "parted", "dosfstools" and "zip" are installed

#   Copyright © 2018-2019 LNCM Contributors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

OUTPUT_VERSION=v0.4.0
DOWNLOAD_VERSION=v0.4.0
ALP=alpine-rpi-3.8.2-armhf.tar.gz
IMG=lncm-box-${OUTPUT_VERSION}.img
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

echo 'Check for existing wpa_supplicant.automatic.conf'
if [ -f ./wpa_supplicant.automatic.conf ]; then
    echo "WPA supplicant automatic file exists, bootstrapping the network configuration"
    cp ./etc/wpa_supplicant/wpa_supplicant.conf ./etc/wpa_supplicant/wpa_supplicant.conf.bak
    cp ./wpa_supplicant.automatic.conf etc/wpa_supplicant/wpa_supplicant.conf
fi

echo 'Generate fresh box.apkovl.tar.gz from source'
sh make_apkovl.sh
# Cleanup files we created
if [ -f ./etc/wpa_supplicant/wpa_supplicant.conf.bak ]; then
    echo 'Restore old WPA Supplicant after making apkovl (and deleting the backup file)'
    cp ./etc/wpa_supplicant/wpa_supplicant.conf.bak ./etc/wpa_supplicant/wpa_supplicant.conf
    rm ./etc/wpa_supplicant/wpa_supplicant.conf.bak
fi

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
  wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${IOT}
fi
if ! [ -f $FIX ]; then
  echo "${FIX} not found, fetching..."
  wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${FIX}
fi
if ! [ -f $CACHE ]; then
  echo "${CACHE} not found, fetching..."
  wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${CACHE}
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
echo -e "\nDone!\nYou may flash your ${IMG}.zip using Etcher or dd the ${IMG}"
