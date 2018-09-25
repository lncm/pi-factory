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

unzip   -d /home/pi/bundle   /boot/bundle.zip   bitcoin.conf bitcoind_version bitcoind.service torrc bluetooth-MACs bt-reconnect.sh  2> /dev/null
sudo rm -f /boot/bundle.zip

sudo apt-get update

sudo apt-get install -y   git jq tmux miniupnpc nmap ufw tree bc

### UFW

sudo ufw allow ssh comment "Allow SSH on firewall"
sudo ufw allow 8333 comment "Allow connections to/from Bitcoind"
sudo ufw enable
sudo ufw status verbose

# upgrade AFTER UFW
sudo apt-get -y upgrade

### Bitcoin (from sources)

# install all dependencies needed to build Bitcoind
sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libminiupnpc-dev libzmq3-dev

cd ~

# get/update bitcoind source code
if [ ! -d ~/bitcoin ]; then
  git clone https://github.com/bitcoin/bitcoin.git
  cd bitcoin
else
  cd bitcoin
  git pull origin master
  git fetch --tags
fi

git checkout "$(cat /home/pi/bundle/bitcoind_version)"

./autogen.sh
./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" --enable-cxx  --disable-shared --with-pic --disable-tests --disable-bench --enable-upnp-default --without-gui --disable-wallet
make
sudo make install

sudo /bin/cp /home/pi/bundle/bitcoind.service /etc/systemd/system/
sudo systemctl enable bitcoind

mkdir -p /home/pi/.bitcoin
cp /home/pi/bundle/bitcoin.conf /home/pi/.bitcoin/


### Tor
# NOTE: The tor installed here is old-ish, but still it's good enough for the usecase here

sudo apt-get install -y tor tor-arm

sudo /bin/cp /home/pi/bundle/torrc /etc/tor/

# allow user pi (and Bitcoind) to communicate with Tor
sudo usermod -a -G debian-tor pi

sudo systemctl restart tor@default

# Wait until Tor starts and creates `hostname` with info about the hidden ssh service
max_wait=55
while sudo test ! -f /var/lib/tor/ssh/hostname; do
  sleep 1

  max_wait=$((max_wait-1))
  if [ ${max_wait} -eq "0" ]; then
    echo "55s passed to no avail… giving up and continuing…"
    break
  fi
done

sudo zip -j   -u /boot/secrets.zip   /var/lib/tor/ssh/hostname


# TODO: WiFi hotspot
# TODO: disable SWAP(?)



# Install metrics
wget -qO- https://gist.githubusercontent.com/meeDamian/fec388a943e0d4e64c876e6196a8d18f/raw/15117a1b58cbe4fe0896840517dd87e7eadaf8e0/install.sh | sudo sh

# TODO: "check if `blocks/` and `chainstate/` exist"-service

# Bluetooth
sudo apt-get install -y python-dbus

cd ~
git clone https://github.com/mk-fg/fgtk.git

# TODO: BT reconnection


rm -rf /home/pi/bundle/

# Disable HDMI (do this last)
sudo /usr/bin/tvservice -o

wrap_up
