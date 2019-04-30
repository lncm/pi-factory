#!/bin/sh

# Upgrades an LNCM Box in place via FAT partition

OUTPUT_VERSION=v0.4.1
DOWNLOAD_VERSION=v0.4.0
ALP=alpine-rpi-3.8.2-armhf.tar.gz
REL=v3.8
IMG=lncm-box-${OUTPUT_VERSION}.img
IOT=iotwifi.tar.gz
NGINX=nginx.tar.gz
FIX=modloop-rpi2.tar.gz
CACHE=cache.tar.gz
MNT=/mnt/lncm
DEV=/dev/mmcblk0p1

if [ "$(id -u)" -ne "0" ]; then
	echo "This script must be run as root"
	exit 1
fi

# cmd_exists() {
#   $(command -v ${1} 2>&1 1>/dev/null;)
#   ret=$?
#   echo $ret
#   return $ret
# }

# if  [ "$(cmd_exists apk)" -eq "0" ]; then
#   echo "Found Alpine-based system, installing dependencies"
#   apk add parted zip unzip
# fi

# if [ "$(cmd_exists apt)" -eq "0" ]; then
#   echo "Found Debian-based system, installing dependencies"
#   apt install -y parted zip unzip
# fi

# check_deps() {
#   cmd_exists parted >/dev/null || exit 1
#   cmd_exists zip >/dev/null || exit 1
#   cmd_exists unzip >/dev/null || exit 1
#   echo "Found required dependencies"
# }

echo "Upgrading SD card in place"
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
	wget http://dl-cdn.alpinelinux.org/alpine/${REL}/releases/armhf/${ALP}
fi

if ! [ -f ${IOT} ]; then
	echo "${IOT} not found, fetching..."
	wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${IOT}
fi

if ! [ -f ${FIX} ]; then
	echo "${FIX} not found, fetching..."
	wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${FIX}
fi

if ! [ -f ${CACHE} ]; then
	echo "${CACHE} not found, fetching..."
	wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${CACHE}
fi

if ! [ -f ${NGINX} ]; then
	echo "${NGINX} not found, fetching..."
	wget https://github.com/lncm/pi-factory/releases/download/${DOWNLOAD_VERSION}/${NGINX}
fi

echo "Unmount"
umount "${DEV}"

echo "Mount FAT partition"
mount "${DEV}" "${MNT}"

rm -rvf ${MNT}
mkdir -p ${MNT}

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

echo "Create fresh apkovl"
cd ..
sh make_apkovl.sh
cd lncm-workdir

echo "Copy latest box.apkovl tarball"
cp ../box.apkovl.tar.gz ${MNT}

echo "Flush writes to disk"
sync

echo "Unmount"
umount ${MNT}

echo "Done!"
echo "You can reboot your system to upgrade"
