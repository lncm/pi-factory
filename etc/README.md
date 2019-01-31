# `/etc/`

This dir contains the initial system configuration shipped with the box.

## `apk/`

This dir contains initial configuration for `apk`, Alpine's package management suite.

### `keys/alpine-devel@lists.alpinelinux.org-524d27bb.rsa.pub` & `keys/alpine-devel@lists.alpinelinux.org-58199dcc.rsa.pub`

Contains a key needed to verify packages(?) can be verified here

> **TODO_0:** verify description

> **TODO_1:** add link to source


### `protected_paths.d/ca-certificates.list`

???


### `protected_paths.d/lbu.list`

???


### `arch`

CPU arch (?)


### `cache`

A symlink to… ???


### `repositories`

??? source ???


### `world`

???


## `conf.d/hostname`

Sets hostname of the device.


## `conf.d/loadkmap` 

???


## `init.d/`

### `avahi-daemon`

Avahi is … ??? and this is a daemon that manages it. 


### `docker-compose`

Needs more docs.


### `iotwifi`

Needs more docs.


### `lncm`

Needs more docs.


### `lncm-online`

Needs more docs.


### `lncm-post`

Needs more docs.


### `portainer`

Needs more docs.


### `sshd`

Needs more docs.


## `iotwifi/wificfg.json` 

???


## `keymap/us*`

???


## `lbu/lbu.conf`

???


## `network/interfaces`

???


## `runlevels/`

???


### `boot/`

???


### `default/`

???


### `shutdown/`

???


### `sysinit/`

???


## `ssh/ssh_host_[ec]dsa_key[.pub]`

The existence of these two pairs of dummy files prevents the generation of these keys that we deem insecure.


## `ssh/sshd_config`

This is a configuration file for the SSH daemon


## `tor/torrc`

This file configures the Tor daemon

> **TODO:** needs cleanup!


## `udhcpc/udhcpc.conf`

???


## `wpa_supplicant/wpa_supplicant.conf`

This file specifies what Wi-Fis will the Box be connect to.


## `zoneinfo/UTC`

???


## `fstab`

Needs more docs


## `group` & `group-`

???


## `hostname`

A second file that sets the hostname?


## `hosts`

Defines How the box is visible to itself.

> **TODO:** Why `.localdomain` and not `.local`?


## `localtime`

A symlink to… ???


## `motd`

_Message Of The Day_ displayed upon ssh session init.

> **TODO:** should be generated with new version number upon each bundle build instead.


## `passwd` & `passwd-`

??? 


## `rc.conf`

???

 
## `resolv.conf`

???


## `shadow` & `shadow-`

???
