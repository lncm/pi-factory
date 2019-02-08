#!/bin/sh

# make_cache.sh
#
# updates and packages cache as cache.tar.gz
# to be run as sudo on Alpine armhf

WORLD=/etc/apk/world
LOCATION=/media/mmcblk0p1/cache # initial cache location
#LOCATION=/var/cache/apk # default of installed boxes
OUTPUT=cache.tar.gz

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

echo "Setting apk cache to ${LOCATION}"
setup-apkcache ${LOCATION}

echo "Syncing cache"
apk cache sync -v

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true

echo "Remove cache dir"
rm -rf cache

echo "Remove cache tarball"
rm -v cache.tar.gz

echo "Copy cache files"
cp -r ${LOCATION} cache

echo "Bundling cache"
# Folder to be compressed must be called cache
tar cvzf ${OUTPUT} --exclude '.DS_Store' cache

echo "Restoring previous ${WORLD}"
cp ${WORLD}.backup ${WORLD}