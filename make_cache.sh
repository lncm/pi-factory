#!/bin/sh

# make_cache.sh
#
# updates and packages cache as cache.tar.gz
# to be run as sudo on Alpine armhf

WORLD=/etc/apk/world
#LOCATION=/media/mmcblk0p1/cache # initial cache location
NORMAL_LOCATION=/var/cache/apk # default of installed boxes
WORKDIR=/home/lncm/pi-factory/lncm-workdir
OUTPUT=cache.tar.gz

cmd_exists() {
  $(command -v ${1} 2>&1 1>/dev/null;)
  echo $?
}

if  [ ! "$(cmd_exists apk)" -eq "0" ]; then
  echo "Not an Alpine-based system, aborting"
  exit 1
fi

mkdir -p ${WORKDIR}

cd ${WORKDIR} || exit

echo "Cleaning up..."

echo "Remove cache dir"
rm -rfv ${WORKDIR}/cache

echo "Remove cache tarball"
rm -v ${WORKDIR}/cache.tar.gz

echo "Making backup of ${WORLD}"
cp -v ${WORLD} ${WORLD}.backup

echo "Creating new minimal ${WORLD}"
echo -e "alpine-base" > ${WORLD}
echo -e "avahi" >> ${WORLD}
echo -e "dbus" >> ${WORLD}
echo -e "docker" >> ${WORLD}
echo -e "openssh" >> ${WORLD}
echo -e "wireless-tools" >> ${WORLD}
echo -e "wpa_supplicant" >> ${WORLD}

mkdir -p ${WORKDIR}/cache

echo "Setting apk cache to ${WORKDIR}/cache"
setup-apkcache ${WORKDIR}/cache

echo "Syncing cache"
apk update && \
apk cache sync -v --no-cache

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

# echo "Copy cache files"
# cp -rv ${LOCATION} cache

echo "Bundling cache"
# Folder to be compressed must be called cache
tar cvzf ${WORKDIR}/${OUTPUT} --exclude '.DS_Store' cache

echo "Restoring previous ${WORLD}"
cp ${WORLD}.backup ${WORLD}

echo "Restoring previous apk cache location"
setup-apkcache ${NORMAL_LOCATION}