#!/usr/bin/env bash

echo -ne "Checking if run as root…\t"
if [[ "$(id -u)" -ne "0" ]]; then
    echo -e "ERR\n\n\tThis script must be run as root\n"
    exit 1
fi
echo "OK"

# currently only Alpine is fully supported
echo -ne "Checking if we're running on Alpine…\t"
if command -v apk 2>&1 1>/dev/null; [[ "$?" -ne "0" ]]; then
  echo -e "ERR\n\n\tThis script is currently only compatible with Alpine\n"
  exit 1
fi
echo "OK"

# make sure all needed dependencies are installed before proceeding
REQUIRED_DEPENDENCIES=( parted wget )
for i in "${REQUIRED_DEPENDENCIES[@]}"; do
    echo -ne "Checking if ${i} is installed…\t"
    if command -v "${i}" 2>&1 1>/dev/null; [[ "$?" -ne "0" ]]; then
      echo -e "ERR\n\n\tThis script requires ${i} to run. Please install it and try again.\n"
      exit 1
    fi
    echo "OK"
done

VERSION=${VERSION:-dev}
echo -ne "Checking if build version is specified…\t"
if [[ "${VERSION}" == "dev" ]]; then
    echo -e "ERR\n\n\tVERSION not specified, building 'dev'\n\t\tTo build a release, try: VERSION=v0.0.1 ./make_all.sh\n"
else
    echo "OK"
fi

IMG="lncm-box-${VERSION}.img"
ALPINE_IMAGE=${ALPINE_IMAGE:-alpine-rpi-3.9.0-armhf.tar.gz}
echo "Building ${IMG} on top of ${ALPINE_IMAGE} now"


echo -ne "Checking for default wpa_supplicant.conf…\t"
if [[ -f ./defaults/wpa_supplicant.conf ]]; then
    cp ./defaults/wpa_supplicant.conf ./etc/wpa_supplicant/wpa_supplicant.conf
    echo "FOUND & COPIED"
fi
echo "NOT FOUND"

echo -ne "Checking for default authorized_keys…\t"
if [[ -f ./defaults/authorized_keys ]]; then
    mkdir -p ./home/lncm/.ssh/
    cp ./defaults/authorized_keys ./home/lncm/.ssh/
    echo "FOUND & COPIED"

    echo -ne "\tDisabling password login for sshd…\t"
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' ./etc/ssh/sshd_config
    echo "OK"
fi
echo "NOT FOUND"

echo -ne "Checking for local copy of ${ALPINE_IMAGE}…\t"
if [[ ! -f ./downloads/${ALPINE_IMAGE} ]]; then
    echo -ne "NOT FOUND\n\tDownloading ${ALPINE_IMAGE}…\t"
    wget -q --show-progress -P downloads/ http://dl-cdn.alpinelinux.org/alpine/v3.9/releases/armhf/${ALPINE_IMAGE}
    if [[ "$?" -ne "0" ]]; then
        echo -e "ERR\n\n\tUnable to download specified Alpine image\n"
        exit 1
    else
        echo
    fi
else
    echo "OK"
fi

echo -ne "Verifying the integrity of ${ALPINE_IMAGE}…"
wget -q -P downloads/ http://dl-cdn.alpinelinux.org/alpine/v3.9/releases/armhf/${ALPINE_IMAGE}.asc
if [[ "$?" -ne "0" ]]; then
    echo -e "ERR\n\n\tUnable to download specified Alpine image signature\n"
    exit 1
else
    echo
fi

# `ncopa.acs` key is Downloaded from: https://alpinelinux.org/downloads/
gpg --import ncopa.asc

gpg --verify downloads/${ALPINE_IMAGE}.asc
if [[ "$?" -ne "0" ]]; then
    echo -e "ERR\n\tImage verification FAILED. Please investigate.\n"
    exit 1
fi

# TODO: extract files from the repo to the filesystem, and remove extractable files from our repo.

# TODO: sh make_apkovl.sh
