# Readme for variant-alpine


## Usage

1. Fetch official Alpine armhf [tar.gz](http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/armhf/alpine-rpi-3.8.1-armhf.tar.gz) for Raspberry Pi.

1. (if not already present) Create FAT32L partition on SD card (fdisk type 0x0C).

3. Extract tarball to SD card, e.g. `tar xvzpf alpine-rpi-3.8.1-armhf.tar.gz -C /Volumes/PI`

4. Copy box.apkovl.tar.gz from this repo to SD card, or modify and re-compress one to suit your needs.
## Access

First boot will take some time as ssh host keys are generated.

If the box has working internet it can be accessed using `ssh box.local`, if no internet is available at boot it can only be reached by IP address.

- **username**: lncm
- **password**: chiangmai
- **root password**: chiangmai

## Customizations

#### Networking
- Change your WiFi settings in `etc/wpa_supplicant/wpa_supplicant.conf` and re-create apkovl.
- Alternatively, run `setup-interfaces` if you have access to a running box.

#### Misc

- Run `setup-hostname` `setup-timezone` `setup-keymap` `setup-dns` to customize to your needs.

### Re-creating apkovl.tar.gz from source

`cd variant-alpine`

`tar cvzpf box.apkovl.tar.gz etc home`

### Unpacking apkovl from tar.gz
`tar xvzpf box.apkovl.tar.gz`

## Creating new apkovl

1. `lbu pkg /path/to/tar.gz`

 *Important notes for distributing fresh apkovl*
 
 **Remove unique and security sensitive files**
 
`rm etc/machine-id`

`rm etc/docker/key.json`

`rm etc/ssh/ssh_host_*`

Rewrite `/etc/resolv.conf` to be network independent.

Be mindful of passwords you set.
