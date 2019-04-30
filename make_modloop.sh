#!/bin/sh

# NOTE: needed due to a bug in Alpine release, making WiFi/Ethernet
# not work in some conditions. Can be removed once bug is fixed upstream.
#
# Creates modloop-rpi2.tar.gz with WiFi patch for RPI 3B+
# which contains modloop-rpi2, an xz compressed squashfs
# filesystem with block size 131072 and 100% dict-size

ALP=alpine-rpi-3.8.2-armhf.tar.gz
REL=v3.8
FIRMWARE=brcm-firmware.zip
FIRMWARE_URL=https://github.com/lncm/pi-factory/files/2714861
WORKDIR=/home/lncm/lncm-workdir
mkdir -p ${WORKDIR}
cd ${WORKDIR} || exit

if [ ! -f ${FIRMWARE} ]; then
	echo "brcm firmware not found, fetching..."
	wget $FIRMWARE_URL/$FIRMWARE
fi

cmd_exists() {
	$(command -v ${1} 2>&1 1>/dev/null)
	echo $?
}

if [ "$(cmd_exists apk)" -eq "0" ]; then
	apk update && apk add squashfs-tools unzip
fi

if [ "$(cmd_exists apt)" -eq "0" ]; then
	apt update && apt install squashfs-tools unzip
fi

rm -rf brcmfmac*
unzip brcm-firmware.zip

if ! [ -f ${ALP} ]; then
	echo "${ALP} not found, fetching..."
	wget http://dl-cdn.alpinelinux.org/alpine/${REL}/releases/armhf/${ALP}
fi

rm -rf alp-distro
mkdir alp-distro
tar xvzf ${ALP} -C alp-distro

mkdir /mnt/squash
mount -o loop -t squashfs alp-distro/boot/modloop-rpi2 /mnt/squash

mkdir squash-tmp
cp -r /mnt/squash/* squash-tmp/

umount /mnt/squash
rmdir /mnt/squash

cp -v brcmfmac43455-sdio.bin squash-tmp/modules/firmware/brcm/
cp -v brcmfmac43455-sdio.txt squash-tmp/modules/firmware/brcm/
cp -v brcmfmac43455-sdio.clm_blob squash-tmp/modules/firmware/brcm/

rm modloop-rpi2
mksquashfs squash-tmp/ modloop-rpi2 -b 131072 -comp xz -Xdict-size 100%
rm -rf squash-tmp

tar cvzf modloop-rpi2.tar.gz modloop-rpi2
