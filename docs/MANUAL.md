Welcome to Pi-Factory's documentation!
======================================

Pi-Factory builds Alpine Linux images with *armhf* architecture ready for booting on any Raspberry Pi.

Most of the user interaction is done thru our `noma` CLI tool

For example:

    noma info

## Customization & Settings

These options apply to creating your own images for burning to microSD card.

#### LND Auto-unlock script

Before running, **make_img.sh** or **make_apkovl.sh**

If you wish to import your own seed, put the seed into seed.txt at ```home/lncm/seed.txt```

**Note** For the seed file, one word should exist on each line.

If you wish to save the password, do a ```touch home/lncm/save_password``` (This option is on by default)

#### Security

If you wish to disable passwords altogether (highly recommended, especially vs the default password), simply place a file called ```authorized_keys.automatic``` into the root of this repository with all your public keys.

Passwords should be disabled when you create a new image.

For those who still are using password authentication it is recommended that you change both root and lncm users with the ```passwd``` utility.

Also, renaming the hotspot and changing the password is another thing that you need to do - the file is  ```/etc/iotwifi/wificfg.json``` as the password is public.

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

