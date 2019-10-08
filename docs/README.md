Pi-Factory
===========================================

### _Easily build your own Alpine Linux box on Raspberry PI or Raspberry Zero!_

This repository lets you build you build an _[Alpine](https://alpinelinux.org) Linux_ box for [Raspberry Pi](https://www.raspberrypi.org) Model B/B+/4/Zero

[![Documentation Status](https://readthedocs.org/projects/noma/badge/?version=latest)](https://pi-factory.readthedocs.io/en/latest/?badge=latest)


### Features

- pi-factory is now a persistent OS Only! For Nodes, please refer to earlier versions or go to the [noma](https://github.com/lncm/noma) project
- Latest version updated to Alpine 3.10.2
- We now have 64 bit (aarch64) and 32 bit images (armhf). The Raspberry PI 3/3b works well on 64 bit
- Deterministic builds. Images now built and released automatically through github actions.



Hardware Requirements
---------------------

* **Raspberry Pi**
    * Recommended: model 3B+
    * Optional: case, heatsink, LAN cable, HDMI cable and monitor (for troubleshooting and issue tracking), Keyboard (to use for troubleshooting and issue tracking)


* **microSD** card
    * Recommended: SanDisk 16GB or more
    * microSD card to USB adapter or built-in hardware

    Quality goes over quantity here!

* **Power Supply** (5V/2.5A) with micro-USB cable
    * Recommended: official Raspberry Pi power supply
    * Alternatively:
        * high-quality USB charger (e.g. Samsung)
        * short USB to micro-USB cable. (a longer cable can work with 5.1V chargers)

    **Warning!** Your Raspberry Pi will *not work* properly without a correctly rated power supply and cable, and may result in data loss. We are not responsible if you lose any data.


Instructions
------------

1. Download [Etcher](https://www.balena.io/etcher/)
2. Download the image from the [Releases page](https://github.com/lncm/pi-factory/releases) or simply clone the ```https://github.com/lncm/pi-factory.git``` repository on github
3. Insert SD Card and open up Etcher
4. Etch one of the images onto the SD card
5. Remount the SD card and create a file called ```wpa_supplicant.conf```
6. Inside the file put the following

```
network={
	ssid="Your Wifi SSID goes here"
	key_mgmt=WPA-PSK
	psk="YOUR Password goes here"
}
```

7. Unmount the drive and put it into a PI or PI zero and then start it up. And in about 10-20 minutes (PI-Zero will take longer), you will be able to login through avahi/mdns ```box.local``` , or if you don't have avahi/mdns on your desktop you will need to grab the IP address from plugging in your PI to a TV or from your router.


Access
------

### Users & Passwords

* lncm
    - **username**: lncm
    - **password**: chiangmai


* root
    - **username**: root
    - **password**: chiangmai

**Note:** `sudo` is not installed, use `su` instead. We also highly recommend that you change the password.



### Command-line via ssh
`ssh lncm@box.local`

**Note:** First boot will take some time as ssh host keys are generated.


#### Advanced configuration

When building the image yourself you can create a ```wpa_supplicant.automatic.conf``` file with all your wifi passwords.

You may disable several stuff by placing an empty file inside the FAT partition.

Filename | Description
------------ | -------------
noswap | disables SWAP generation (not recommended unless you know what you are doing!)
noavahi | disables install for avahi-daemon / mdns discovery (not recommended unless you know what you are doing!)
nodocker | disables Docker installation
nopython | Disables python3 installation
notor | Disables tor installation

Documentation
-------------
[Read the Docs](https://pi-factory.readthedocs.io/en/latest/?badge=latest)


Building
--------
To generate a fresh image from source run `./make_img.sh` as __root__ on a *Debian*, *Ubuntu* or *Alpine* system.

For convenience, we also support `vagrant` to automate setting up your development VM.

### MacOS instructions:

Install dependencies ([homebrew](https://brew.sh), virtualbox, vagrant):
```sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew cask install virtualbox
brew cask install vagrant
git clone pi-factory
cd pi-factory
```

Create VM and generate image:
* `vagrant up`

Rebuild image without wiping VM:
* `vagrant up --provision`

Also useful:
* `vagrant ssh`
* `vagrant halt`
* `vagrant destroy -f`
* `brew cask install vagrant-manager` (optional menu-bar utility)

Support
-------

If you are having problems, please [create an issue](https://github.com/lncm/pi-factory/issues/new)


Contribute
----------

Bug reports, pull-requests and suggestions are very welcome!

- [Issue Tracker](http://github.com/lncm/pi-factory/issues)
- [Source Code](https://github.com/lncm/pi-factory)
- [Contributing Guidelines](https://github.com/lncm/pi-factory/blob/master/CONTRIBUTING.md)

License
-------

The project is licensed under the permissive Apache 2.0 license.
