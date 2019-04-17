#!/bin/sh

# Creates a zipped & partitioned image file for burning onto SD cards
# 256MB bootable FAT32L partition with official Alpine linux and lncm-box
# Make sure "parted", "dosfstools" and "zip" are installed

OUTPUT_VERSION=v0.5.0
DOWNLOAD_VERSION=v0.4.1
ALP=alpine-rpi-3.8.2-armhf.tar.gz
REL=v3.8
IMG=lncm-box-${OUTPUT_VERSION}.img
IOT=iotwifi.tar.gz
NGINX=nginx.tar.gz
FIX=modloop-rpi2.tar.gz
CACHE=cache.tar.gz
MNT=/mnt/lncm

if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

cmd_exists() {
  $(command -v ${1} 2>&1 1>/dev/null;)
  ret=$?
  echo $ret
  return $ret
}

if  [ "$(cmd_exists apk)" -eq "0" ]; then
  echo "Found Alpine-based system, installing dependencies"
  apk add parted zip unzip
fi

if [ "$(cmd_exists apt-get)" -eq "0" ]; then
  echo "Found Debian-based system, installing dependencies"
  apt-get install -y parted zip unzip
fi

check_deps() {
  cmd_exists parted >/dev/null || exit 1
  cmd_exists zip >/dev/null || exit 1
  cmd_exists unzip >/dev/null || exit 1
  echo "Found required dependencies"
}

echo "Building ${IMG}"
echo "Using ${ALP} as base distribution"

echo 'Check for existing wpa_supplicant.automatic.conf'
if [ -f ./wpa_supplicant.automatic.conf ]; then
    echo "WPA supplicant automatic file exists, bootstrapping the network configuration"
    cp ./etc/wpa_supplicant/wpa_supplicant.conf ./etc/wpa_supplicant/wpa_supplicant.conf.bak
    cp ./wpa_supplicant.automatic.conf etc/wpa_supplicant/wpa_supplicant.conf
fi

echo 'Check for authorized_keys.automatic'
if [ -f ./authorized_keys.automatic ]; then
    echo "Authorized keys file exists, bootstrapping the ssh authorized keys file"
    if [ ! -d ./home/lncm/.ssh ]; then
        mkdir -p ./home/lncm/.ssh
    fi
    cp ./authorized_keys.automatic ./home/lncm/.ssh/authorized_keys
    echo "Reconfiguring SSHD to not allow for passwords"
    cp ./etc/ssh/sshd_config ./etc/ssh/sshd_config.bak
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' ./etc/ssh/sshd_config
fi

echo 'Generate fresh box.apkovl.tar.gz from source'
sh make_apkovl.sh
# Cleanup files we created
if [ -f ./etc/wpa_supplicant/wpa_supplicant.conf.bak ]; then
    echo 'Restore old WPA Supplicant after making apkovl (and deleting the backup file)'
    cp ./etc/wpa_supplicant/wpa_supplicant.conf.bak ./etc/wpa_supplicant/wpa_supplicant.conf
    rm ./etc/wpa_supplicant/wpa_supplicant.conf.bak
fi

fetch_wifi() {
    echo "Checking for wifi manager"
    mkdir -p home/lncm/public_html/wifi
    if [ ! -f home/lncm/public_html/wifi/index.html ]; then
      echo "Fetch wifi manager"
      wget -O home/lncm/public_html/wifi/index.html --no-verbose \
	      https://raw.githubusercontent.com/lncm/iotwifi-ui/master/dist/index.html || exit
    fi
}
fetch_wifi

# Cleanup authorized_keys
if [ -d ./home/lncm/.ssh ]; then
    echo "Remove .ssh directory"
    rm -fr ./home/lncm/.ssh
fi

if [ -f ./etc/ssh/sshd_config.bak ]; then
    echo "Restoring sshd_config to be equal with last commit"
    cp ./etc/ssh/sshd_config.bak ./etc/ssh/sshd_config
    rm ./etc/ssh/sshd_config.bak
fi

mkdir -p lncm-workdir
cd lncm-workdir || exit

if ! [ -f ${ALP} ]; then
  echo "${ALP} not found, fetching..."
  wget --no-verbose http://dl-cdn.alpinelinux.org/alpine/${REL}/releases/armhf/${ALP}
fi

if ! [ -f ${IOT} ]; then
  echo "${IOT} not found, fetching..."
  wget --no-verbose https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${IOT}
fi

if ! [ -f ${FIX} ]; then
 echo "${FIX} not found, fetching..."
 wget --no-verbose https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${FIX}
fi

if ! [ -f ${CACHE} ]; then
  echo "${CACHE} not found, fetching..."
  wget --no-verbose https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${CACHE}
fi

if ! [ -f ${NGINX} ]; then
  echo "${NGINX} not found, fetching..."
  wget --no-verbose https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${NGINX}
fi

echo "Create and mount 256MB image"
dd if=/dev/zero of=${IMG} bs=1M count=256 && \
    DEV=$(losetup -f) && \
    losetup -f ${IMG} && \
    echo "Create 256MB FAT32 partition and filesystem" && \
    parted -s "${DEV}" mklabel msdos mkpart p fat32 2048s 100% set 1 boot on && \
    mkfs.vfat "${DEV}"p1 -IF 32

if ! [ -d ${MNT} ]; then
  mkdir ${MNT}
fi

echo "Mount FAT partition"
mount "${DEV}"p1 "${MNT}"

echo "Extract alpine distribution"
tar -xzf ${ALP} -C ${MNT}/ --no-same-owner

echo "Extract iotwifi container"
tar -xzf ${IOT} -C ${MNT}/ --no-same-owner

echo "Extract nginx container"
tar -xzf ${NGINX} -C ${MNT}/ --no-same-owner

echo "Extract cache dir for docker and avahi"
tar -xzf ${CACHE} -C ${MNT}/ --no-same-owner

echo "Patch RPi3 WiFi"
tar -xzf ${FIX} -C ${MNT}/boot/ --no-same-owner

echo "Copy latest box.apkovl tarball"
cp ../box.apkovl.tar.gz ${MNT}

echo "Flush writes to disk"
sync

echo "Unmount"
umount ${MNT}

losetup -d "${DEV}"
echo "Compress img as zip"

zip -r ${IMG}.zip ${IMG}

echo "Done!"
echo "You may flash your ${IMG}.zip using Etcher or dd the ${IMG}"
