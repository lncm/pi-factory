#!/bin/sh

# make_cache.sh
# updates and packages cache
# to be run as sudo on Alpine armhf

LOCATION=/media/mmcblk0p1/cache
#LOCATION=/var/cache/apk

apk cache sync -v

# Disables adding resource-forks on MacOS
export COPYFILE_DISABLE=true



tar czf cache.tar.gz --exclude '.DS_Store' ${LOCATION}