#!/bin/bash

exec > ~/setup.log 2>&1
set -x

# $1 - file path
# $2 - file name
function save_log() {
  sudo mkdir -p /boot/setup-logs/

  file_name="$2"
  if [ -s "/boot/setup-logs/${file_name}" ]; then
    file_name="$(/bin/date +%s)-${file_name}"
  fi

  sudo cp "$1/$2" "/boot/setup-logs/${file_name}"
}

function wrap_up() {
  save_log /home/pi setup.log
  save_log /var/log syslog
}
trap 'wrap_up' TERM INT HUP

# needed to prevent apt-get complaining
export DEBIAN_FRONTEND=noninteractive

sudo raspi-config nonint do_change_locale en_US.UTF-8

sudo rm -f /boot/bundle.zip

sudo apt-get update

sudo apt-get install -y   git jq tmux miniupnpc nmap ufw tree bc


#
### UFW
#
sudo ufw allow ssh comment "Allow SSH on firewall"
sudo ufw enable
sudo ufw status verbose

# upgrade AFTER UFW
sudo apt-get -y upgrade


# TODO: disable SWAP(?)

#
### Install metrics
#
wget -qO- https://gist.githubusercontent.com/meeDamian/fec388a943e0d4e64c876e6196a8d18f/raw/15117a1b58cbe4fe0896840517dd87e7eadaf8e0/install.sh | sudo sh

wrap_up
