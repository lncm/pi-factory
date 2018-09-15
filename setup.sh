#!/usr/bin/env bash

# TODO: choose a set location for log
# TODO: graceful shutdown & log copy to `/boot`
exec > setup.log 2>&1
set -x

# NOTE:
#   This script is to be run on first RBP Zero run via `pi-init2`.
#   This script should be safe to be run more than once.
#   Other files that need to be included in the boot partition are:
#     `/boot/ssh` - empty file
#     `/boot/wpa_supplicant.conf` - file containing WiFi credentials and WiFi coutry settings(!)
#     `/boot/bundle.zip`

# set locale to `en_US.UTF-8`
sudo raspi-config nonint do_change_locale en_US.UTF-8

# set hostname to `pi-bitcoin`
sudo raspi-config nonint do_hostname pi-zero

# TODO: other raspi-config commands?

# change password to `newpassword` for `pi` and `root`
# TODO: generate better password(!)
# TODO: save password to BACKUP_DRIVE
echo 'pi:newpassword' | sudo chpasswd
echo 'root:newpassword' | sudo chpasswd

# TODO: bundle everything in a `.zip` file

# get better `sshd_config`
# TODO: bundle the sshd_config together with this script
sudo wget -qN https://gist.githubusercontent.com/meeDamian/6e3b17be9a303f31d5376244c89e6b59/raw/fe95ffe8baab7b5f57bff88b4822a44671b552bc/sshd_config -P /etc/ssh/

# TODO: generate id_ed25519 keypair
# TODO: move private key to BACKUP_DRIVE
# TODO: add pubkey to `home/pi/.ssh/authorized_keys`

sudo apt-get update

# upgrade all raspbian packages to their latest versions
sudo apt-get -y upgrade

# NOTE: need to install a fairly old-ish Tor, as the one from
sudo apt-get install -y tor git jq tmux miniupnpc nmap ufw tree bc

# install all dependencies needed to build Bitcoind
sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libminiupnpc-dev libzmq3-dev

# Get latest Bitcoin stable release
LAST_BITCOIN_RELEASE="$(curl https://api.github.com/repos/bitcoin/bitcoin/releases/latest | jq -r '.tag_name')"

cd ~

# get/update bitcoind source code
if [ ! -d ~/bitcoin ]; then
  git clone https://github.com/bitcoin/bitcoin.git
  cd bitcoin
else
  cd bitcoin
  git pull origin master
fi

# TODO: chenge this to `v0.17.0` once it's released
git checkout 0.17

./autogen.sh
./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" --enable-cxx  --disable-shared --with-pic --enable-upnp-default --without-gui --disable-wallet --disable-tests
make
sudo make install

# add firewall rules
sudo ufw allow ssh comment "Allow SSH on firewall"
sudo ufw allow 8333 comment "Allow connections to/from Bitcoind"
sudo ufw allow in from 192.168.1.1 to 224.0.0.0/4 comment "Remove multicast blocking from log…"
sudo ufw allow in from 192.168.1.1 to 239.0.0.0/8 comment "Remove multicast blocking from log…"

# TODO: enable `ufw`

# TODO: disable HDMI

# TODO: how to do that persist upon reboot?
sudo iw dev wlan0 set power_save off

# TODO: hidden service ssh


# check if `blocks/` and `chainstate/` exist

# TODO: save stuff to /boot
# TODO: sudo halt
