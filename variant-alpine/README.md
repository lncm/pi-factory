# variant-alpine

This repository contains everything necessary to bootstrap a LNCM box for [Raspberry Pi](https://www.raspberrypi.org) versions 0-3B+ based on Alpine Linux.

*[Alpine](https://alpinelinux.org) is a security-oriented, lightweight Linux distribution based on musl libc and Busybox.*

Alpine [wiki](https://wiki.alpinelinux.org/) holds further information related to system administration.

## Usage

1. Fetch official Alpine armhf [tar.gz](http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/alpine-rpi-3.8.1-armhf.tar.gz) for Raspberry Pi.

```bash
wget "http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/alpine-rpi-3.8.1-armhf.tar.gz"
```

2. (if not already present) Create FAT32L partition on SD card (fdisk type 0x0C).

3. Extract tarball to SD card.

```bash
tar xvzpf alpine-rpi-3.8.1-armhf.tar.gz -C /path/to/sdcard
```

4. Extract lncm-box.tar.gz from releases page to SD card.

5. Optionally if you like building your own stuff, create box.apkovl.tar.gz from source and place in SD card root, to ship changes before first boot.

```bash
# If you are using a MAC
export COPYFILE_DISABLE=true

# You may omit .DS_Store if you aren't using a Mac, but you can keep it in
tar cvzpf box.apkovl.tar.gz --exclude '.DS_Store' etc home
```

6. Ensure that your SD Card is bootable. For Linux/OS X you can use [Etcher](https://etcher.io/), for Windows use Rufus if you like GUI or diskpart if you are comfortable with command line. Instructions for [Linux is found here],, (https://www.lifewire.com/create-a-linux-bootable-usb-drive-from-linux-4117072), furthermore instructions for [Windows can be found here](https://mspoweruser.com/how-to-create-a-bootable-usb-drive-for-windows-10/)

7. If you have a Raspberry PI 3b+ then fetch this patch if you installed 3.8.1 or lower and put it in **/boot**. [zip](https://github.com/lncm/pi-factory/files/2569132/modloop-rpi2.zip)

```bash
wget "https://github.com/lncm/pi-factory/files/2569132/modloop-rpi2.zip"

# If zip not installed
apt install unzip

# Extract
unzip modloop-rpi2.zip
# take out the trash
rm -fr __MACOSX

# Copy (or move) to boot folder in SD Card
cp modloop-rpi2 /path/to/sdcard/boot
```

8. Put card into RPI and Pray that it all works

## Access

**Note:** First boot will take some time as ssh host keys are generated.

### Authentication
- **username**: lncm
- **password**: chiangmai
- **root password**: chiangmai

**Note:** `sudo` is not installed, use `su` instead

### Using ssh
`ssh lncm@box.local`

**Note:** if no internet is available at boot, `cache` directory with avahi-daemon and dbus must be provided to enable `box.local` access. Alternatively, the IP address can be used. MAC addresses have a distinct Raspberry Pi Foundation prefix.

### Using serial 
(serial TTY via TTL on uart)

Connect cable to *GND*, *RX*, *TX* pins, make sure you are using 3.3V and **not** 5V to prevent damage! With some devices RX & TX may have to be crossed.

Add `enable_uart=1` to `config.txt` on SD card FAT partition. (may not be necessary on older models)

e.g. `screen /dev/tty.usbserial-XYZ 115200`

### WiFi hotspot

The box can provide it's own WiFi hotspot to ease access and configuration.

- **WiFi name** (SSID): "LNCM-Box"
- **WiFi password**: "lncm box"

## Customizations

### Settings

**Note:** By default Alpine will not persist user changes upon reboot. Remember to commit all changes with `lbu commit`.

#### Networking
- Change your WiFi settings in `etc/wpa_supplicant/wpa_supplicant.conf` and re-create apkovl.
- Alternatively, run `setup-interfaces` if you have access to a running box.

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

#### Misc

There are various configuration tools included to help you customize to your needs:

- `setup-hostname` 
- `setup-timezone` 
- `setup-keymap` 
- `setup-dns`

### Committing changes to SD card

**Important!** **Note:** By default Alpine will not persist user changes upon reboot. *The system is mounted read-only!*

Use `lbu commit` to persist changes. Add `-v` to see what is being committed.

`lbu status` will show changes to be committed.

**Note:** By default `lbu commit` only applies to *some* directories.

### Re-creating apkovl.tar.gz from source

Make sure you are in variant-alpine directory, e.g. `cd variant-alpine`

Set `export COPYFILE_DISABLE=true` to prevent MacOS from adding resource forks to tarballs.

`tar cvzpf box.apkovl.tar.gz --exclude ‘.DS_Store’ etc home`

### Unpacking apkovl from lncm-box.tar.gz

`tar xvzpf box.apkovl.tar.gz`

## Creating new apkovl

`lbu pkg /path/to/tar.gz` will produce a tarball of current system state.

*Important notes for distributing fresh apkovl*
 
**Remove unique and security sensitive files**
 
`rm etc/machine-id`

`rm etc/docker/key.json`

`rm etc/ssh/ssh_host_*`

Rewrite `/etc/resolv.conf` to be network independent.

Be mindful of passwords you set.
