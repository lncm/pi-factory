# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-18.04"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    wget https://raw.githubusercontent.com/alpinelinux/alpine-chroot-install/v0.10.0/alpine-chroot-install \
        && echo 'dcceb34aa63767579f533a7f2e733c4d662b0d1b  alpine-chroot-install' | sha1sum -c \
        || exit 1
    chmod +x alpine-chroot-install
    apt-get install qemu-user-binfmt -y
    ./alpine-chroot-install -b v3.9 -a armhf -m https://mirror.xtom.com.hk/alpine/
    cp /vagrant/chroot_cache.sh .
    chmod +x chroot_cache.sh
    /alpine/enter-chroot ./chroot_cache.sh
    cp -v cache-*.tar.gz /vagrant/
  SHELL
end
