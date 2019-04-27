Pi-Factory
===========================================

### _Create your own bitcoin lightning box!_

This repository lets you build a _bitcoin lightning_ box for [Raspberry Pi](https://www.raspberrypi.org) 3 Model B & 3B+ based on [Alpine](https://alpinelinux.org) Linux.

**Work in progress.** While stable enough for development, this software is subject to change, some of which may be breaking changes.
**Warning!** *Do not put money at stake that you are not willing to lose!*

[![Build Status](https://travis-ci.com/lncm/pi-factory.svg?branch=v0.5)](https://travis-ci.com/lncm/pi-factory)
[![Documentation Status](https://readthedocs.org/projects/noma/badge/?version=latest)](https://pi-factory.readthedocs.io/en/latest/?badge=latest)


### Features

* `Tor` onion-routing for enhanced privacy and improved connectivity
* Lightning Labs' `LND` bundled with our *autoconnect* and *autounlock* tools
* Bitcoin Core `bitcoind` bundled with our implementation of Nicholas Dorier's *fastsync* to drastically reduce initial sync time
* `Alpine Linux`, a security-oriented, lightweight Linux distribution based on musl *libc* and `Busybox`
* Containerization of most components including `nginx`, `iotwifi`, `invoicer`, `bitcoind`, `lnd`
* *Stateless OS* - the microSD card image can be replaced with a newer version *without loss of user data*
* Simple `shell`, `Python` scripts and `Go` backends enable easy auditing and provide a small *attack surface*
* `Docker` & `docker-compose` make updates easier and orchestration painless
* [Future] the microSD card can be mounted in read-only mode for zero-wear operation
* [Future] Redundant storage persistence using RAID 


### LNCM components

* [invoicer](https://github.com/lncm/invoicer): lightweight `bitcoind` and `LND` backend in Go.
* [invoicer-ui](https://github.com/lncm/invoicer-ui): Point of Sale for Bitcoin and Lightning in React.
* [iotwifi-ui](https://github.com/lncm/iotwifi-ui): Wi-Fi connection wizard in React.
* [noma](https://github.com/lncm/noma): CLI node management utility and API in Python.
* [docker-bitcoind](https://github.com/lncm/docker-bitcoind): arm & amd64 support
* [docker-berkeleydb](https://github.com/lncm/docker-berkeleydb): arm & amd64 support
* [docker-lnd](https://github.com/lncm/docker-lnd): arm & amd64 support


Hardware Requirements
---------------------

* **Raspberry Pi**
    * Recommended: model 3B+
    * Optional: case, heatsink, LAN cable
    
    We recommend using a heatsink on 3B+ models to unlock their full sustained performance. Useful, e.g. during syncing or filtering blocks.
    
* **microSD** card
    * Recommended: SanDisk 16GB or more
    * microSD card to USB adapter or built-in hardware
    
    Quality goes over quantity here!
    
* **USB storage** devices
   * Recommended: 4 USB flash drives of 16GB or more
   * Alternatively for bitcoin full-archival nodes: 
        * 2 or 3 flash devices
        * a hard drive or SSD for the blockchain
        
   You may need to use a powered USB hub to prevent undervoltage when using some hard drives.

* **Power Supply** (5V/2.5A) with micro-USB cable
    * Recommended: official Raspberry Pi power supply
    * Alternatively: 
        * high-quality USB charger (e.g. Samsung)
        * short USB to micro-USB cable. (a longer cable can work with 5.1V chargers)
    
    **Warning!** Your Raspberry Pi will *not work* properly without a correctly rated power supply and cable.
    
    You **risk losing bitcoin** and **data** when running your Raspberry Pi in an underpowered state. 
    
Instructions
------------

1. Download [Etcher](https://www.balena.io/etcher/) 
    * *Experienced users:* it is possible to use `dd` instead
2. Download latest [lncm-box.img.zip](
https://github.com/lncm/pi-factory/releases/download/v0.4.1/lncm-box-v0.4.1.img.zip)
3. Run Etcher and follow on-screen instructions to burn `lncm-box.img.zip` to microSD card 
4. Place the SD card in your *Raspberry Pi*
5. Connect your *Raspberry Pi* to a **correctly rated power supply**
6. If you are using wired *LAN*: 
    * connect the cable to your Pi 
    * is your LAN cable active? 
        * congratulations, you are done!
7. If you are using *WiFi*: 
    * find a device with a *web browser* and *WiFi*, e.g. your smartphone or laptop
8. On your device, search for and connect to a *WiFi* network called **LNCM-Box**
    * Password: **lncm box**
9. Open the *web browser* on your device, e.g. `Chrome` or `Safari`
    * Navigate to "[http://box.local/wifi](http://box.local/wifi)"
    * Choose your *WiFi* network from the list
    * Type in your password & *connect*

Your **lightning box** will automatically start installing itself to *microSD* card once it has an internet connection. This usually takes less than *15 minutes* depending on the speed of your card and internet connection.

Once the box has *synced* up the **invoicing** service will be available at [http://box.local/pos](http://box.local/pos). Depending on the speed of your internet connection and your USB storage devices the process may take *30 minutes* to *an hour* or more.

Access
------

### Users & Passwords

* lncm
    - **username**: lncm
    - **password**: chiangmai


* root
    - **username**: root
    - **password**: chiangmai

**Note:** `sudo` is not installed, use `su` instead

### Command-line via ssh
`ssh lncm@box.local`

**Note:** First boot will take some time as ssh host keys are generated.

### Connect to WiFi hotspot

The Raspberry Pi lightning box provides it's own WiFi hotspot to ease access and configuration.

- **WiFi name** (SSID): "LNCM-Box"
- **WiFi password**: "lncm box"


- **IP address**: 192.168.27.1
- **hostname**: box.local

Documentation
-------------
[Read the Docs](https://pi-factory.readthedocs.io/en/latest/?badge=latest)


Building
--------
To generate a fresh image from source run `make_img.sh` as __root__ on a *Debian*, *Ubuntu* or *Alpine* system.

For convenience, we also support `vagrant` to automate setting up your development VM.

### MacOS instructions:

Install dependencies (brew, virtualbox, vagrant):
* install [Homebrew](https://brew.sh)
* `brew cask install virtualbox`
* `brew cask install vagrant`
* `git clone pi-factory`
* `cd pi-factory`

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

If you are having problems, please let us know.
We have a public [chat room](https://gitter.im/lcnm/box)


Contribute
----------

Bug reports, pull-requests and suggestions are very welcome!

- [Issue Tracker](http://github.com/lncm/pi-factory/issues)
- [Source Code](https://github.com/lncm/pi-factory)

In the Wild
-----------

There are two public [installations](nodes.lncm.io) of this lightning box in Chiang Mai, Thailand acting as Bitcoin and Lightning points of sale in combination with a tablet.

Please do let us know about your own or those you spot!

License
-------

The project is licensed under the permissive Apache 2.0 license.
