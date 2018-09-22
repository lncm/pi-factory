# Portable Bitcoin Node on Raspberry Pi Zero

This repo contains all setup scripts necessary to setup a portable Full Bitcoin Node.

The final setup includes:

* Bitcoin Full Pruned Node available through clearnet and Tor
* ssh available via clearnet and Tor
* gets internet from your phone via Bluetooth tethering
* creates an open hotspot called "Bitcoin"
* has captive portal with instructions on how to connect and sync

# Setup process

Setting Raspberry Pi Zero is 4 easy steps:

1. Prepare SD Card
2. Let RBP setup itself
3. Backup
4. Enjoy & play with it


# Step One: Prepare SD Card

This step _can_ take a very long time, depending on your internet connection and speed of the microSD card. You can speed it up by downloading (or using already downloaded) official Raspbian Lite image - just drop it into the root of the repo directory and run the script as usual - `make all`.

## [REQUIRED] WiFi credentials

This is the only required thing to do in this step. Open `./wpa_supplicant.conf` from the root of this directory and replace:

* `${COUNTRY}` with a two-letter code of the country you will be using this RBP in (regulatory reasons ¯\\\_(ツ)\_/¯)
* `${SSID}` with the name of the WiFi network
* `${PASSWORD}` with a password to it

## [OPTIONAL] Grant yourself access

The 2nd step, where the RBP bootstraps itself can take multiple hours, during which you will not be able to see what's going on **unless** you specify one of the below:

### password

If you input any password into `./password` file it will be used as a `pi` and `root` user login password, and you'll be able to ssh to the Pi.

If you do not input the password, a random one will be generated, and made available as part of the backup in step 3.

### ssh key

If you have a `id_ed25519.pub` or `id_rsa.pub` ssh key, just drop it into the root of this repo and you'll be able to ssh to the Pi using it, while it's bootstrapping itself.

If you do not provide an ssh key, `id_ed25519` keypair will be generated, and made available as part of the backup in step 3.

## [OPTIONAL] Other configs

You can also inspect, and change the config files before running the script preparing the microSD card:

* `bitcoin.conf` - this is the minimal Bitcoind config that will be used
* `bitcoind_version` - can be either a tag or a branch name of Bitcoin Core that will be build and installed
* `bitcoind.service` - is a systemd service file that will be responsible for starting Bitcoind
* `sshd_config` - contains a minimal, and secure sshd config that will be used. Note that `PasswordAuthentication yes` will be changed to `no` if any ssh key is provided.
* `torrc` - contains minimal caonfig allowing Bitcoind to communicate with Tor, and allowing ssh via Tor to your Pi later (setup instructions will be provided as part of the backup in step 3).

**NOTE:** Changing these files might result in step 2 failing in unpredictable ways!

# Stop Two: Let RBP setup itself

This step **requires a working 2.4GHz WiFi connection**
