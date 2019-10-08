Welcome to Pi-Factory's documentation!
======================================

Pi-Factory builds Alpine Linux images with **aarch64** and **armhf** architecture ready for booting on any Raspberry Pi.

## Customization & Settings

These options apply to creating your own images for burning to microSD card.

Before running, **make_img.sh** or **make_apkovl.sh** you may wish to etch your wifi settings into the box so it will complete its setup smoothly. To do this, create a file called ```wpa_supplicant.automatic.conf``` and place the following in there:

```
network={
	ssid="Your Wifi SSID goes here"
	key_mgmt=WPA-PSK
	psk="YOUR Password goes here"
}
```


#### Security

If you wish to disable passwords altogether (highly recommended, especially vs the default password), simply place a file called ```authorized_keys.automatic``` into the root of this repository with all your public keys.

Passwords should be disabled when you create a new image.

For those who still are using password authentication it is recommended that you change both root and lncm users with the ```passwd``` utility.

#### Networking

If you have console access:

As **root** use `wpa_passphrase` tool to set wifi settings

`wpa_passphrase "WiFi Name" "Password" >> /etc/wpa_supplicant/wpa_supplicant.conf`

Or, run `setup-interfaces` if you have access to a running box.

In order to ship correct WiFi configuration, edit settings in `etc/wpa_supplicant/wpa_supplicant.conf`, run `make_apkovl.sh` and copy **box.apkovl.tar.gz** to SD card root directory (FAT partition).

Alternatively you may copy wpa_supplicant.conf to the FAT partition of the box (can be done at any time). The box will boot up and copy this file into the correct place and OVERWRITE any changes.

### Alpine specific

Alpine [wiki](https://wiki.alpinelinux.org/) holds further information related to system administration.

#### Committing changes to SD card

*Initially the system is mounted read-only!*

**Important note:** Alpine will not persist user changes upon reboot until it is installed and restarted.

Use `lbu commit` to persist changes. Add `-v` to see what is being committed.

`lbu status` will show changes to be committed.

**Note:** By default `lbu commit` only applies to *some* directories.

After setup is fully complete, the system will be a full persistant system

#### Package management

- `apk update` Update repositories
- `apk upgrade` Upgrade packages
- `apk add` Install package
- `apk del` Uninstall package

#### Init system

- `rc-update` show startup services

Installation of LNCM specific components belongs in `etc/init.d/lncm`. The script is [OpenRC](https://wiki.gentoo.org/wiki/OpenRC) compatible and must be executable, without a file name extension.

`etc/apk/world` contains all apk packages to be installed by LNCM's install script.

- `service -l` list available services

The boot sequence is logged to `/var/log/rc.log` by default.

More information in OpenRC [user guide](https://github.com/OpenRC/openrc/blob/master/user-guide.md)

#### Misc

There are various configuration tools included to help you customize to your needs:

- `setup-hostname` (change the hostname)
- `setup-timezone` (change the timezone)
- `setup-keymap`
- `setup-dns` (change the DNS)
- `setup-alpine` (Go through ALL the setup scripts. Useful if you choose to setup networking manually)

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
