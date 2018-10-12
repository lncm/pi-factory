#!/bin/bash

exec > ~/pre-setup.log 2>&1
set -x

# $1 - file path
# $2 - file name
function save_log() {
  mkdir -p /boot/setup-logs/

  file_name="$2"
  if [ -s "/boot/setup-logs/${file_name}" ]; then
    file_name="$(/bin/date +%s)-${file_name}"
  fi

  cp "$1/$2" "/boot/setup-logs/${file_name}"
}

function wrap_up() {
  save_log /root pre-setup.log
  save_log /var/log syslog
}
trap 'wrap_up' TERM INT HUP

export DEBIAN_FRONTEND=noninteractive

# set locale to `en_US.UTF-8`
raspi-config nonint do_change_locale en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
update-locale LANG='en_US.UTF-8'
update-locale LANGUAGE='en_US:en'

# Setup Swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo \
"
/swapfile none swap sw 0 0" | tee --append /etc/fstab

# Update packages
apt-get update

# Install `unzip` (extract config files necessary in this stoep from `bundle.zip`) and `wamerican-small` dictionary to generate password
apt-get install -y zip unzip wamerican-small


#
### SSH Daemon Setup
#
#  Replaces the magic of https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/master/debian/raspberrypi-sys-mods.sshswitch.service
#  See also: https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/master/debian/raspberrypi-sys-mods.regenerate_ssh_host_keys.service
update-rc.d ssh enable && invoke-rc.d ssh start
dd if=/dev/hwrng of=/dev/urandom count=1 bs=4096
rm -f -v /etc/ssh/ssh_host_*_key*
/usr/bin/ssh-keygen -A -v


# unzip files that will be used now to /root/bundle/
unzip   -d /root/bundle   /boot/bundle.zip   password hostname id_rsa.pub id_ed25519.pub pi-setup.sh pi-setup.service pi-shutdown.service sshd_config    2> /dev/null

# copy pi-setup script to home directory of the `pi` user
mkdir -p /home/pi/bin
cp /root/bundle/pi-setup.sh /home/pi/bin/
chown -R $(id -u pi):$(id -g pi) /home/pi/bin
chmod +x /home/pi/bin/pi-setup.sh


# make sure that right scripts are run on the next boot
cp /root/bundle/pi-setup.service /etc/systemd/system/
cp /root/bundle/pi-shutdown.service /etc/systemd/system/
systemctl enable pi-setup
systemctl enable pi-shutdown


# create temporary directory to store secrets in
mkdir /boot/secrets

#
### Password
#
# Generate password, if not provided
if [ ! -s /root/bundle/password ]; then
  LC_ALL=C grep -x '[a-z]*' /usr/share/dict/words | shuf --random-source=/dev/urandom -n 12 | paste -sd "-" > /boot/secrets/password
else
  cp /root/bundle/password /boot/secrets/
fi

password="$(cat /boot/secrets/password)"

# set either the provided or the generated password for `pi` and `root`
echo   "pi:${password}" | chpasswd
echo "root:${password}" | chpasswd


#
### SSH key
#
# generate key, if not provided
if [ ! -s /root/bundle/id_ed25519.pub ] && [ ! -s /root/bundle/id_rsa.pub ]; then
  ssh-keygen -N "" -o -a 100 -t ed25519 -f /boot/secrets/id_ed25519

else
  # only copy known keys, ignore missing ones
  cp /root/bundle/id_{rsa,ed25519}.pub /boot/secrets/ 2>/dev/null

  # disable password for ssh ONLY if a key was **provided by user**
  sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
fi

(umask 077; mkdir -p /home/pi/.ssh; touch /home/pi/.ssh/authorized_keys)
chown -R $(id -u pi):$(id -g pi) /home/pi/.ssh

# enable SSH access wither via the provided or generated key(s)
if [ -s /boot/secrets/id_ed25519.pub ]; then
  cat /boot/secrets/id_ed25519.pub >> /home/pi/.ssh/authorized_keys
fi
if [ -s /boot/secrets/id_rsa.pub ]; then
  cat /boot/secrets/id_rsa.pub >> /home/pi/.ssh/authorized_keys
fi

# make SSH access more secure
/bin/cp -f /root/bundle/sshd_config /etc/ssh/


#
### Bluetooth (part 1)
#
# Allow user pi to interact with Bluetooth stuff w/o sudo.
# NOTE: Done here instead of `pi-setup.sh`, because changing group needs re-login
usermod -G bluetooth -a pi


# pack all secrets into a single `secrets.zip` archive
zip -r -m /boot/secrets.zip /boot/secrets


#
### HDMI
#
# disable for this run
sudo /usr/bin/tvservice -o

# disable permanently, if not disabled already
[ -z "$(grep "usr/bin/tvservice" /etc/rc.local)" ] && \
    sed -i "s|^exit 0$|\# Disable HDMI\n/usr/bin/tvservice -o\n\nexit 0|g" /etc/rc.local

#
### hostname
#
# See https://raspberrypi.stackexchange.com/a/66939/8375 for a list of all the raspi-config magic you may want ot automate.
raspi-config nonint do_hostname "$(cat /root/bundle/hostname)"


#
### Cleanup
#
# all unzipped files from bundle are placed where necessary, so clean-up
rm -rf /root/bundle/

# Move self to completed
mkdir -p /boot/run-once.d/completed
mv /boot/run-once.sh /boot/run-once.d/completed


wrap_up

shutdown --reboot now
