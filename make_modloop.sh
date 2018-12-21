#!/bin/sh

# Creates modloop-rpi2.tar.gz with WiFi patch for RPI 3B+
# which contains modloop-rpi2, an xz compressed squashfs
# filesystem with block size 131072 and 100% dict-size


mkdir lncm-workdir
cd lncm-workdir

wget https://github.com/RPi-Distro/firmware-nonfree/blob/master/brcm/brcmfmac43455-sdio.txt
wget https://github.com/RPi-Distro/firmware-nonfree/blob/master/brcm/brcmfmac43455-sdio.clm_blob

apk add squashfs-tools

mkdir alpine-rpi-3.8.2
tar xvzf alpine-rpi-3.8.2-armhf.tar.gz -C alpine-rpi-3.8.2

mkdir /mnt/squash
mount -o loop -t squashfs alpine-rpi-3.8.2/boot/modloop-rpi2 /mnt/squash

mkdir squash-tmp
cp -r /mnt/squash/* squash-tmp/

cp brcmfmac43455-sdio.txt squash-tmp/modules/firmware/brcm/
cp brcmfmac43455-sdio.clm_blob squash-tmp/modules/firmware/brcm/

mksquashfs squash-tmp/ modloop-rpi2 -b 131072 -comp xz -Xdict-size 100%

tar cvzf modloop-rpi2.tar.gz modloop-rpi2
