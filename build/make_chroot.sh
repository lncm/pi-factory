#!/bin/sh

# Create Alpine chroot via Ubuntu, then run make_cache_chroot.sh
apt-get update
wget https://raw.githubusercontent.com/alpinelinux/alpine-chroot-install/v0.10.0/alpine-chroot-install \
    && echo 'dcceb34aa63767579f533a7f2e733c4d662b0d1b  alpine-chroot-install' | sha1sum -c \
    || exit 1
chmod +x alpine-chroot-install
apt-get install qemu-user-binfmt -y
./alpine-chroot-install -b v3.9 -a armhf -m https://mirror.xtom.com.hk/alpine/
chmod +x ./build/make_cache_chroot.sh
/alpine/enter-chroot ./build/make_cache_chroot.sh
