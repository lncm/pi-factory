#!/bin/sh

WORLD=/etc/apk/world
ALPINE_RELEASE=3.9.4

echo "Running make_cache"

echo "alpine-base" > ${WORLD}
echo "avahi" >> ${WORLD}
echo "dbus" >> ${WORLD}
echo "docker" >> ${WORLD}
echo "openssh" >> ${WORLD}
echo "wireless-tools" >> ${WORLD}
echo "wpa_supplicant" >> ${WORLD}

DIR=$(pwd)
mkdir /tmp/cache
ln -s /tmp/cache /etc/apk/cache
apk update && apk cache -v sync
cd /tmp
tar cvzf cache-${ALPINE_RELEASE}.tar.gz cache
cp cache-${ALPINE_RELEASE}.tar.gz ${DIR}/
echo "Done"
exit
