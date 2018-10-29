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

unzip   -d /home/pi/bundle   /boot/bundle.zip   torrc 2> /dev/null
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


# TODO: replace with newer Tor
# TODO: detect arch; for "normal" and RBP3 install new Tor, for RBP 0 install old from apt-get
##
#### Tor (old-ish, but good 'nuff)
##
#sudo apt-get install -y tor tor-arm
#
#sudo /bin/cp /home/pi/bundle/torrc /etc/tor/
#
## allow user pi (and Bitcoind) to communicate with Tor
#sudo usermod -a -G debian-tor pi
#
#sudo systemctl restart tor@default
#
## Wait until Tor starts and creates `hostname` with info about the hidden ssh service
#max_wait=10 # in seconds
#while sudo test ! -f /var/lib/tor/ssh/hostname; do
#  sleep 1
#
#  max_wait=$((max_wait-1))
#  if [ ${max_wait} -eq "0" ]; then
#    echo "10s passed to no avail… giving up and continuing…"
#    break
#  fi
#done
#
#sudo zip -j   -u /boot/secrets.zip   /var/lib/tor/ssh/hostname

# TODO: enable some more SWAP(?)

curl -fsSL get.docker.com | sh

#
### Install metrics
#
wget -qO- https://gist.githubusercontent.com/meeDamian/fec388a943e0d4e64c876e6196a8d18f/raw/15117a1b58cbe4fe0896840517dd87e7eadaf8e0/install.sh | sudo sh

rm -rf /home/pi/bundle/

wrap_up
