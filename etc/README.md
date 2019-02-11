# `/etc/`

This dir contains the initial system configuration shipped with the box.

## `apk/`

This dir contains initial configuration for `apk`, Alpine's package management suite.

### `keys/alpine-devel@lists.alpinelinux.org-524d27bb.rsa.pub` & `keys/alpine-devel@lists.alpinelinux.org-58199dcc.rsa.pub`

Contains a key needed to verify packages(?) can be verified here

Original files being in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/alpine-keys-2.1-r1.apk/etc/apk/keys/*`


### `protected_paths.d/ca-certificates.list`

???


### `protected_paths.d/lbu.list`

List of files / directories which are whitelisted by apkovl system
(Only files listed here are included in the overlay filesystem)


### `arch`

Based on alpine 3.9.0 armhf

CPU arch armv7l


### `cache`

A symlink to the location of apk (packages) cache
Initially: `/media/mmcblk0p1/cache/`
After persistent installation: `/var/cache/apk`


### `repositories`

List of mirrors we are fetching from


### `world`

List of packages we have chosen to install

## `conf.d/hostname`

Sets hostname of the device.


## `conf.d/loadkmap` 

Sets keyboard keymap (US)

## `init.d/`

### `avahi-daemon`

Avahi is responsible for `box.local` name advertisement and this is a daemon that manages it. 


### `docker-compose`

Needs more docs.


### `iotwifi`

Needs more docs.


### `lncm`

Initial installation stage (runs from RAM)
Prepares sd card for persistent installation (format with ext4, etc)


### `lncm-online`

A global dependency which checks whether the system is connected to internet once at boot


### `lncm-post`

post installation script, responsible for installing docker-compose, python3, setting up USB storage, node containers, etc


### `portainer`

Web dashboard for docker
Allows managing and installing containers

Needs more docs.


### `sshd`

Needs more docs.


## `iotwifi/wificfg.json` 

* Sets it's own Access Point's IP to 192.168.27.1
* Sets dnsmasq (dhcp server) address range to 192.168.27.100-150
* Creates `LNCM-Box` SSID on channel 6 with "lncm box" passphrase


## `keymap/us*`

US keyboard keymap


## `lbu/lbu.conf`

Alpine LBU backup config

Original file in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/alpine-conf-3.8.1-r1.apk/etc/lbu/lbu.conf`

Difference being: `LBU_MEDIA=mmcblk0p1` extra in our file. 


## `network/interfaces`

static configuration of
* lo, loopback

dhcp network configuration of
* wlan0, wifi
* eth0, lan


## `runlevels/`

*Determines the order of startup services*

Can also add own directory to add a runlevel



### `boot/`

kernel, modules for boot


### `default/`
*Services to start during normal system runlevel*
(sshd, ntpd, crond, docker-compose, etc)


### `shutdown/`

Scripts to run at shutdown


### `sysinit/`

Early system services runlevel (drivers)


## `ssh/ssh_host_[ec]dsa_key[.pub]`

The existence of these two pairs of dummy files prevents the generation of these keys that we deem insecure.


## `ssh/sshd_config`

This is a configuration file for the SSH daemon

Original file in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/openssh-server-common-7.9_p1-r2.apk/etc/ssh/sshd_config`

> **TODO:** What changed?


## `tor/torrc`

This file configures the Tor daemon

> **TODO:** needs cleanup!


## `udhcpc/udhcpc.conf`

DHCP server config


## `wpa_supplicant/wpa_supplicant.conf`

This file specifies what Wi-Fis will the Box be connect to.


## `zoneinfo/UTC`

UTC timezone file


## `fstab`

Filesystem table
Needs more docs


## `group` & `group-`

List of groups

Original file in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/alpine-baselayout-3.1.0-r3.apk/etc/group`, plus appended lines:

```
avahi:x:86:avahi
messagebus:x:101:messagebus
docker:x:102:
lncm:x:1001: 
```

`group-` file is nowhere to be found.

## `hostname`

A second file that sets the hostname?


## `hosts`

Defines How the box is visible to itself.

> **TODO:** Why `.localdomain` and not `.local`?


## `localtime`

Symlink to timezone file (UTC by default)


## `motd`

_Message Of The Day_ displayed upon ssh session init.

> **TODO:** should be generated with new version number upon each bundle build instead.


## `passwd` & `passwd-`

Users accounts and secrets

Original file in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/alpine-baselayout-3.1.0-r3.apk/etc/passwd`, plus appended lines:

```
avahi:x:86:86:Avahi System User:/var/run/avahi-daemon:/sbin/nologin
messagebus:x:100:101:messagebus:/dev/null:/sbin/nologin
lncm:x:1001:1001:Linux User,,,:/home/lncm:/bin/ash
```

`passwd-` file is nowhere to be found.

## `rc.conf`

OpenRC init system configuration
Defines where to log, etc

Original file from `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/openrc-0.39.2-r3.tar.gz/etc/rc.conf`

> **TODO:** what are the changes?

 
## `resolv.conf`

Default DNS server


## `shadow` & `shadow-`

Users accounts and secrets

Original file in `alpine-rpi-3.9.0-armhf.tar.gz/apks/armhf/alpine-baselayout-3.1.0-r3.apk/etc/shadow`, except:

* stuff added to root, and 
* below is appended:

```
avahi:!:17835:0:99999:7:::
messagebus:!:17835:0:99999:7:::
lncm:$6$tQyFDIFTxJQ9Kncz$RLR2nTlJTSEwcIRboCVdEX07.997XbvKuID2k7wFT7aC245Z82lSC9AoiceApPZlrvVzljLwlnqmdZmqPxF9J0:17836:0:99999:7:::
```

`shadow-` file is nowhere to be found.
