# Portable Bitcoin Node on Raspberry Pi Zero

> **NOTE:** WORK IN PROGRESS!

> **NOTE_2:** Only compatible with MacOS at the moment

This repo contains all setup scripts necessary to setup a portable Full Bitcoin Node.

The final setup includes:

- [x] Bitcoin Full Pruned Node available through clearnet¹ and Tor
- [x] `ssh` available via clearnet¹ and Tor
- [ ] (figured out, but not automated yet) gets internet from your phone via Bluetooth tethering
- [ ] creates an open hotspot called "Bitcoin"
- [ ] has captive portal with instructions on how to connect and sync

> ¹ - Clearnet availability depends completely on Pi's ability to auto-configure the device giving it internet


# Setup process

Setting Raspberry Pi Zero is 4 easy steps:

1. Prepare
2. Wait
3. Backup
4. Enjoy


# Step One: Prepare

This step _can_ take a very long time, depending on your internet connection and the speed of your microSD card. You can speed it up by downloading (or using already downloaded) official Raspbian Lite image - just drop it into the root of the repo directory and run the script as usual - `make all`.

## [REQUIRED] WiFi credentials

This is **the only required** thing to do in this step. Open `./wpa_supplicant.conf` from the root of this directory and replace:

* `${COUNTRY}` with a two-letter code of the country you will be using this RBP in (regulatory reasons ¯\\\_(ツ)\_/¯)
* `${SSID}` with the name of the WiFi network
* `${PASSWORD}` with a password to it

## [OPTIONAL] Grant yourself access

The 2nd step, where the RBP bootstraps itself can take multiple hours, during which you will not be able to see what's going on **unless** you specify one of the below:

### password

If you input any password into `./password` file it will be used as a `pi` and `root` user login password, and you'll be able to ssh to the Pi.

If you do not input the password, a random one will be generated, and made available as part of the backup in step 3.

### `ssh` key

If you have a `id_ed25519.pub` or `id_rsa.pub` ssh key, just drop it into the root of this repo and you'll be able to ssh to the Pi using it, while it's bootstrapping itself.

If you do not provide an ssh key, `id_ed25519` keypair will be generated, and made available as part of the backup in step 3.

## Run

After you've set up WiFi and perhaps granted ourself access, just run:

```
make all SD=/dev/disk2
```

Where `/dev/disk2` is the SD card you want to burn your image onto.

## [OPTIONAL] Other configs

You can also inspect, and change the config files before running the script preparing the microSD card:

| File name          | Description
|:------------------:|-------------
| `bitcoin.conf`     | this is the minimal Bitcoind config that will be used
| `bitcoind_version` | can be either a tag or a branch name of Bitcoin Core that will be build and installed
| `bitcoind.service` | is a systemd service file that will be responsible for starting Bitcoind
| `bluetooth-MACs`   | [TODO] This **will** be used to specify bluetooth internet tethering devices
| `hostname`         | you can choose how your RBP will be named, default is `pi-the-box`
| `sshd_config`      | contains a minimal, and secure sshd config that will be used. Note that `PasswordAuthentication yes` will be changed to `no` if any ssh key is provided.
| `torrc`            | contains minimal caonfig allowing Bitcoind to communicate with Tor, and allowing ssh via Tor to your Pi later (setup instructions will be provided as part of the backup in step 3).

**NOTE:** Changing these files might result in step 2 failing in unpredictable ways!

## [PLEASE DON'T CHANGE] Scripts & Services

This is a list of scripts that will be run on your Pi. If you're not sure what you're doing, changing them will most definitely cause the build process to fail.

| File name                   | Description
|:---------------------------:|-------------
| `bt-reconnect.sh`     | [TODO] Runs periodically from cron and ensures that Bluetooth internet connection is still available and working
| `pi-setup.service`    | This is a systemd service that will spawn `pi-setup.sh` upon first boot
| `pi-setup.sh`         | This script runs as user `pi` and sets-up most of the necessary things. It will run for long hours, and during its run it records its work into `/home/pi/setup.log`
| `pi-shutdown.service` | This systemd service ensures that `pi-setup.service` & `pi-shutdown.service` run only once, and that RBP is powered off upon successful completion
| `run-once.sh`         | This is a barebones setup script that only creates the very minimal required environment, and reboots your Pi into `pi-setup.sh`. During its run it records its work into `/root/pre-setup.log`

## [Very Optional] Run_2

If you've decided to change some configs after you've already started `make all` - despair not, just let it finish and then run (before ever putting it into the RBP):

```bash
make write_stuff_to_boot SD=/dev/disk2
```

Where `/dev/disk2` is your SD card. **Note** that you might need to manually reinsert the SD card into your computer.

# Step Two: Let RBP setup itself

This step **requires a working 2.4GHz WiFi connection** and will take multiple hours, after which the RBP will power off completely. If your computer is on the same network as the RBP, you've provided your ssh pubkey or password, and you didn't customize the `hostname`, you can see logs of the progress with a simple:

```bash
ssh pi@pi-the-box.local 'tail -f -n 2000 /home/pi/setup.log'
```


# Step Three: Backup

After RBP has completed the setup, move the SD card back to your computer.

There are two locations there that might be of special interest:

| Location                           | Description
|:----------------------------------:|-------------
| `/Volumes/boot/secrets.zip`        | Contains all secrets related with the pi: `password`, `ssh` key (if not provided one will be generated for you there), and a special ssh over Tor string (TODO: document & explain `HidServAuth`)
| `/Volumes/boot/setup-logs/*` | Contains at least two files: `pre-setup.log` and `setup.log`. In case any of the scrips was run/terminated more than once there might be more files with the same names, but unix timestamp-prefixed.


# Step Four: Enjoy

[WIP] Put your card back & enjoy
