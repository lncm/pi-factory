#!/bin/sh

# make_all.sh
# Generate components and image ready for flashing to SD card
#
# Note: make_container.sh is not being run automatically, as it requires existing docker containers

if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

./build/make_chroot.sh
./build/make_img.sh
