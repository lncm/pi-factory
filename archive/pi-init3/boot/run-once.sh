#!/bin/bash

##  Usage: This script will run once after systemd brings up the network and
#   then get moved into /boot/run-once.d/completed which will be created for
#   you. This script is in this project to serve as an demo of how you might use
#   it. There are several distinct tasks in commented blocks. The recommended
#   use would be to create the /boot/run-once.d/ directory yourself and put
#   each task in its own file and name them so they sort in the order you want
#   them ran.
#   See: http://manpages.ubuntu.com/manpages/bionic/man8/run-parts.8.html

#### Wifi Setup (WPA Supplicant)
##  Replaces the magic of https://github.com/RPi-Distro/raspberrypi-net-mods/blob/master/debian/raspberrypi-net-mods.service
##  See: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
# cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
# network={
#     ssid="testing"
#     psk="testingPassword"
# }
# EOF
# chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
# wpa_cli -i wlan0 reconfigure

#### SSH Daemon Setup
##  Replaces the magic of https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/master/debian/raspberrypi-sys-mods.sshswitch.service
##  See also: https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/master/debian/raspberrypi-sys-mods.regenerate_ssh_host_keys.service
# update-rc.d ssh enable && invoke-rc.d ssh start
# dd if=/dev/hwrng of=/dev/urandom count=1 bs=4096
# rm -f -v /etc/ssh/ssh_host_*_key*
# /usr/bin/ssh-keygen -A -v

#### Update hostname
##  See https://raspberrypi.stackexchange.com/a/66939/8375 for a list of all the raspi-config magic you may want ot automate.
# raspi-config nonint do_hostname "$(cat /boot/hostname)"

#### Get SSH keys for authentication
# github_user=gesellix
# echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1
# if [ $? -eq 0 ]; then
#   (umask 077; mkdir -p /home/pi/.ssh; touch /home/pi/.ssh/authorized_keys)
#   chown -R $(id -u pi):$(id -g pi) /home/pi/.ssh
#   curl -sSL https://github.com/${github_user}.keys >> /home/pi/.ssh/authorized_keys
#   sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
# else
#   echo "Won't install ssh keys, github.com couldn't be reached."
# fi


#### Install some packages
# apt update
# apt install -y vim tmux

#### Do other stuff
# This is just here to help verify that it worked
echo "alias ll='ls -la'" > /home/pi/.bash_aliases
