# LNCM Pi-Factory
### _Create your own bitcoin lightning box!_

This repository contains everything necessary to bootstrap a LNCM box for [Raspberry Pi](https://www.raspberrypi.org) versions 0-3B+ based on Alpine Linux.

*[Alpine](https://alpinelinux.org) is a security-oriented, lightweight Linux distribution based on musl libc and Busybox.*

**Warning!** **Work in progress.** While stable enough for development, this software is subject to change and will require complete reinstallation periodically. 

*Do not put money at stake that you are not willing to lose!*

## Instructions

1. Download [Etcher](https://www.balena.io/etcher/).
2. Download latest [lncm-box.img.zip](
https://github.com/lncm/pi-factory/releases/download/v0.3.0/lncm-box-v0.3.0.img.zip)
3. Run Etcher and follow instructions to burn lncm-box.img.zip to SD card

Your box will automatically start installing itself to SD card once it has an internet connection.

**Experienced users:** Alternatively, use `dd` to burn the lncm-box.img to SD card

## Access

**Note:** First boot will take some time as ssh host keys are generated.

### Authentication

- **username**: lncm
- **password**: chiangmai
- **root password**: chiangmai

**Note:** `sudo` is not installed, use `su` instead

### Using ssh
`ssh lncm@box.local`

### WiFi hotspot

The box provides it's own WiFi hotspot to ease access and configuration.

- **WiFi name** (SSID): "LNCM-Box"
- **WiFi password**: "lncm box"
- **IP address**: 192.168.27.1
- **hostname**: box.local

## Customization & Settings

#### Networking

If you have console access:

As **root** use `wpa_passphrase` tool to set wifi settings

`wpa_passphrase "WiFi Name" "Password" >> /etc/wpa_supplicant/wpa_supplicant.conf`

Or, run `setup-interfaces` if you have access to a running box.

In order to ship correct WiFi configuration, edit settings in `etc/wpa_supplicant/wpa_supplicant.conf`, run `make_apkovl.sh` and copy **box.apkovl.tar.gz** to SD card root directory (FAT partition).

##### IotWiFi Configuration

After connecting to _"LNCM-Box"_ WiFi on your computer you can tell the box to connect to your own home WiFi network by issuing the following command:

```bash
curl -w "\n" -d '{"ssid":"YOUR-SSID-NAME", "psk":"YOUR-PASSWORD"}' \
    -H "Content-Type: application/json" \
    -X POST http://192.168.27.1:8080/connect
```
### Alpine specific

Alpine [wiki](https://wiki.alpinelinux.org/) holds further information related to system administration.

#### Committing changes to SD card

*Initially the system is mounted read-only!*

**Important note:** Alpine will not persist user changes upon reboot until it is installed and restarted. 

Use `lbu commit` to persist changes. Add `-v` to see what is being committed.

`lbu status` will show changes to be committed.

**Note:** By default `lbu commit` only applies to *some* directories.

#### Package management

- `apk update` Update repositories 
- `apk upgrade` Upgrade packages
- `apk add` Install package 
- `apk del` Uninstall package 

#### Init system

- `rc-update add docker boot` Start docker at boot
- `rc-update del docker boot` Remove docker from boot
- `rc-update` show startup services

Installation of LNCM specific components belongs in `etc/init.d/lncm`. The script is [OpenRC](https://wiki.gentoo.org/wiki/OpenRC) compatible and must be executable, without a file name extension.

`etc/apk/world` contains all apk packages to be installed by LNCM's install script.

- `service -l` list available services
- `service docker start` start docker now
- `service docker stop` stop docker now

The boot sequence is logged to `/var/log/rc.log` by default.

More information in OpenRC [user guide](https://github.com/OpenRC/openrc/blob/master/user-guide.md)

#### Misc

There are various configuration tools included to help you customize to your needs:

- `setup-hostname` 
- `setup-timezone` 
- `setup-keymap` 
- `setup-dns`

## Advanced

#### Using nmap

Raspberry Pi's can be easily intentified when on the same subnet by their distinct MAC address.

Using `nmap` you can find your Raspberry Pi like so,

`sudo nmap -v -sn 192.168.0.0/24 | grep -B 2 "Raspberry Pi Foundation"`

#### Connecting to console via serial cable
(serial TTY via TTL on uart)

Connect cable to *GND*, *RX*, *TX* pins, make sure you are using 3.3V and **not** 5V to prevent damage! With some devices RX & TX may have to be crossed.

Add `enable_uart=1` to `config.txt` on SD card FAT partition. (may not be necessary on older models)

e.g. `screen /dev/tty.usbserial-XYZ 115200`

#### Automated builds

Use `make_img.sh` to create latest lncm-box.img

#### Auditing

Follow the steps outlined in `make_img.sh` to create your own image or SD card.

#### Re-creating apkovl.tar.gz from source

`make_apkovl.sh`

#### Unpacking apkovl from lncm-box.tar.gz

`tar xzf box.apkovl.tar.gz`

#### Creating new apkovl

`lbu pkg /path/to/tar.gz` will produce a tarball of current system state.

#### *Important notes for distributing fresh apkovl:*
 
**Remove unique and security sensitive files**
 
`rm etc/machine-id`

`rm etc/docker/key.json`

`rm etc/ssh/ssh_host_*`

Rewrite `/etc/resolv.conf` to be network independent.

Be mindful of passwords you set.
