#!/bin/sh

# make_cache.sh
#
# updates and packages cache as cache.tar.gz
# to be run as sudo on Alpine armhf

WORLD=/etc/apk/world
#LOCATION=/media/mmcblk0p1/cache # initial cache location
NORMAL_LOCATION=/var/cache/apk # default of installed boxes
LOCATION=/home/lncm/pi-factory/lncm-workdir/cache
OUTPUT=cache.tar.gz

if [ ! -d lncm-workdir ]; then
  mkdir lncm-workdir
fi

cd lncm-workdir

echo "Cleaning up..."
echo "Remove cache dir"
rm -rfv cache

echo "Remove cache tarball"
rm -v cache.tar.gz

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

if [ ! -d ${LOCATION} ]; then
  mkdir ${LOCATION}
fi

echo "Setting apk cache to ${LOCATION}"
setup-apkcache ${LOCATION}

echo "Syncing cache"
apk update && \
apk cache sync -v --no-cache

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

# echo "Copy cache files"
# cp -rv ${LOCATION} cache

echo "Bundling cache"
# Folder to be compressed must be called cache
tar cvzf ${OUTPUT} --exclude '.DS_Store' cache

echo "Restoring previous ${WORLD}"
cp ${WORLD}.backup ${WORLD}

echo "Restoring previous apk cache location"
setup-apkcache ${NORMAL_LOCATION}