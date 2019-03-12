#!/bin/sh

# NOTE: needed due to a bug in Alpine release, making WiFi/Ethernet
# not work in some conditions. Can be removed once bug is fixed upstream.
#
# Creates modloop-rpi2.tar.gz with WiFi patch for RPI 3B+
# which contains modloop-rpi2, an xz compressed squashfs
# filesystem with block size 131072 and 100% dict-size

ALP=alpine-rpi-3.9.2-armhf.tar.gz
FIRMWARE=https://github.com/lncm/pi-factory/files/2714861/brcm-firmware.zip

mkdir lncm-workdir
cd lncm-workdir

if ! [[ -f ${FIRMWARE} ]]; then
  echo "Brcm firmware not found, fetching..."
  wget https://github.com/lncm/pi-factory/files/2714861/brcm-firmware.zip
fi

apk update && apk add squashfs-tools unzip

unzip brcm-firmware.zip

if ! [[ -f ${ALP} ]]; then
  echo "${ALP} not found, fetching..."
  wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/${ALP}
fi

mkdir alp-distro
tar xvzf ${ALP} -C alp-distro

mkdir /mnt/squash
mount -o loop -t squashfs alp-distro/boot/modloop-rpi2 /mnt/squash

mkdir squash-tmp
cp -r /mnt/squash/* squash-tmp/

umount /mnt/squash
rmdir /mnt/squash

cp brcmfmac43455-sdio.bin squash-tmp/modules/firmware/brcm/
cp brcmfmac43455-sdio.txt squash-tmp/modules/firmware/brcm/
cp brcmfmac43455-sdio.clm_blob squash-tmp/modules/firmware/brcm/

rm modloop-rpi2
mksquashfs squash-tmp/ modloop-rpi2 -b 131072 -comp xz -Xdict-size 100%
rm -rf squash-tmp

tar cvzf modloop-rpi2.tar.gz modloop-rpi2
