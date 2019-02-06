#!/bin/sh

# make_cache.sh
# updates and packages cache
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

echo "Bundling cache"
tar cvzf ${OUTPUT} --exclude '.DS_Store' ${LOCATION}

echo "Restoring previous ${WORLD}"
cp ${WORLD}.backup ${WORLD}