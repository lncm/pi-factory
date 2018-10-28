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

unzip   -d /home/pi/bundle   /boot/bundle.zip   bitcoin.conf bitcoind-version bitcoind.service torrc 2> /dev/null
sudo rm -f /boot/bundle.zip

sudo apt-get update

sudo apt-get install -y   git jq tmux miniupnpc nmap ufw tree bc screen vim

#
### UFW
#
sudo ufw allow ssh comment "Allow SSH on firewall"
sudo ufw allow 8333 comment "Allow connections to/from Bitcoind"
sudo ufw allow 9735 comment "Allow people to actually open a channel to the box"
sudo ufw enable
sudo ufw status verbose

# upgrade AFTER UFW
sudo apt-get -y upgrade


#
### Tor (old-ish, but good 'nuff)
#
sudo apt-get install -y tor tor-arm

sudo /bin/cp /home/pi/bundle/torrc /etc/tor/

# allow user pi (and Bitcoind) to communicate with Tor
sudo usermod -a -G debian-tor pi

sudo systemctl restart tor@default

# Wait until Tor starts and creates `hostname` with info about the hidden ssh service
max_wait=10 # in seconds
while sudo test ! -f /var/lib/tor/ssh/hostname; do
  sleep 1

  max_wait=$((max_wait-1))
  if [ ${max_wait} -eq "0" ]; then
    echo "10s passed to no avail… giving up and continuing…"
    break
  fi
done

sudo zip -j   -u /boot/secrets.zip   /var/lib/tor/ssh/hostname


# TODO: detect `-source` suffix in `bitcoind-version`; if present build from source, if not build from binaries
BITCOINVER=`cat bundle/bitcoind-version`
if [[ $BITCOINVER == *"source"* ]]; then
    echo "Building bitcoin from source"
    #
    #### Bitcoin (from sources)
    ##
    ## install all dependencies needed to build Bitcoind
    sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libminiupnpc-dev libzmq3-dev
    #
    cd ~
    #
    ## get/update bitcoind source code
    if [ ! -d ~/bitcoin ]; then
      git clone https://github.com/bitcoin/bitcoin.git
      cd bitcoin
    else
      cd bitcoin
      git pull origin master
      git fetch --tags
    fi
    #
    git checkout "$(cat /home/pi/bundle/bitcoind-version)"
    #
    ./autogen.sh
    ./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" --enable-cxx  --disable-shared --with-pic --disable-tests --disable-bench --enable-upnp-default --without-gui --disable-wallet
    make
    sudo make install
    #
    #sudo /bin/cp /home/pi/bundle/bitcoind.service /etc/systemd/system/
    #sudo systemctl enable bitcoind
    #
    mkdir -p /home/pi/.bitcoin
    # TODO: actually generate a bitcoin.conf we can use
    cp /home/pi/bundle/bitcoin.conf /home/pi/.bitcoin/
else
    echo "Using pre-built binary"
    # Double check if its actually a supported platform
    # TODO: use my detect arch script as fallback
    if [ $(uname -m) == "armv7l" ]; then
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common

        # verify key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88

        echo "deb [arch=armhf] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list

        # update sources
        sudo apt-get update

        # install docker
        sudo apt-get install -y docker-ce

        # setup docker containers
        sudo usermod -G docker pi # Make sure the permissions are set
        sudo systemctl start docker # Make sure docker is started

        # create folder structure
        mkdir -p /home/pi/data/btc
        mkdir -p /home/pi/data/lightningd

        # TODO: actually generate a bitcoin.conf instead so lightning
        # connects to bitcoind with no configuration.
        cp /home/pi/bundle/bitcoin.conf /home/pi/data/btc
        # TODO: generate a lightning config
        touch /home/pi/data/lightningd/config

        # grab docker containers
        # TODO: Make the bitcoinver more integrated
        if ! docker images | grep 0.17.0-arm7; then
            docker pull lncm/bitcoind:0.17.0-arm7
        fi
        # TODO: make a lightningver too
        if ! docker images | grep 0.6.1-arm7; then
            docker pull lncm/clightning:0.6.1-arm7
        fi
        cat <<EOF >/home/pi/data/ln.sh
#!/bin/bash
/usr/local/bin/lightningd --lightning-dir=/data/lightningd
EOF
        chmod 755 /home/pi/data/ln.sh
    fi
fi



# TODO: disable SWAP(?)

#
### Install metrics
#
wget -qO- https://gist.githubusercontent.com/meeDamian/fec388a943e0d4e64c876e6196a8d18f/raw/15117a1b58cbe4fe0896840517dd87e7eadaf8e0/install.sh | sudo sh

rm -rf /home/pi/bundle/

wrap_up
