PI_INIT3_FILES=pi-init3/boot/cmdline.txt pi-init3/boot/pi-init3

SUPPORTED_IMAGES=2018-06-27 2018-10-09

# if no IMAGE= specified choose the newest
IMAGE ?= $(lastword $(SUPPORTED_IMAGES))

# That's a template for the WiFi file that can be generated from your OS keystore by using:
#		make wpa_supplicant.automatic.conf
define WPA_SUPPLICANT
country=<COUNTRY>
ctrl_interface=/var/run/wpa_supplicant
update_config=1

network={
    ssid="<SSID>"
    psk="<PASSWORD>"
}

endef
export WPA_SUPPLICANT


# TODO: should there be a default VARIANT?
# TODO: describe in more detail what the below does
VARIANT ?= box
ifeq ($(VARIANT),zero)
	# TODO: split this into steps
	VARIANT_DEPS = $(patsubst variant-zero/%,tmp/%,$(filter-out variant-zero/dbus,$(wildcard variant-zero/*)))
else ifeq ($(VARIANT),box)
	VARIANT_DEPS = $(wildcard variant-box/*)
else ifeq ($(VARIANT),blank)
	VARIANT_DEPS = $(wildcard variant-blank/*)
else ifeq ($(VARIANT),builder)
	VARIANT_DEPS = $(wildcard variant-builder/*)
endif

VARIANT_DEPS := $(filter-out tmp/README.md,$(VARIANT_DEPS))


%-raspbian-stretch-lite.zip:
	@[ ! -f $@ ] && { \
		echo "Downloading $@…"; \
		echo; \
		echo "PROTIP: Downloading it from Raspberry Pi Foundation can take a"; \
		echo "        very long time… To speed it up, consider downloading it"; \
		echo "        using .torrent from the official website:"; \
		echo "        https://www.raspberrypi.org/downloads/raspbian/ ."; \
		echo; \
		echo "  Make sure the version you're downloading is: "; \
		echo "  	$@"; \
		echo; \
		echo "  After the download completes, copy it into the same directory as Makefile, "; \
		echo "  and run the script again."; \
		echo; \
		echo "To interrupt current download press control+c (^c)"; \
		echo; \
		{ \
			$(eval IMAGE_DATE := $(shell echo $@ | cut -d- -f-3)) \
			{ \
				$(eval UPLOAD_DATE := $(shell [ "$(IMAGE_DATE)" = "2018-10-09" ] && echo "2018-10-11" || \
					{ [ "$(IMAGE_DATE)" = "2018-06-27" ] && echo "2018-06-29"; } || \
					echo "$(IMAGE_DATE)" )) \
				curl -OJs "http://director.downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-$(UPLOAD_DATE)/$@"; \
			} || rm -f $@; \
		}; \
	}


## verify raspbian image and unzip it into an .img file
2018-06-27-raspbian-stretch-lite.img: 2018-06-27-raspbian-stretch-lite.zip
	@shasum -a 256 -c <<< "3271b244734286d99aeba8fa043b6634cad488d211583814a2018fc14fdca313  $<"
	@unzip -n $<

2018-10-09-raspbian-stretch-lite.img: 2018-10-09-raspbian-stretch-lite.zip
	@shasum -a 256 -c <<< "98444134e98cbb27e112f68422f9b1a42020b64a6fd29e2f6e941a3358d171b4  $<"
	@unzip -n $<


pi-init3:
	git submodule update --init --recursive


clean:
	rm -f boot/*

tmp:
	mkdir -p tmp


##
## common (used in at least 2 variants) files (to be zipped into bundle.zip)
##
# If set, the contents of this file will be set as password for users `pi` & `root` on the Pi
tmp/password: password
	grep "^[^#]" $< > $@ || { : > $@; }

# If set, the uncommented contents of this file are set as a hostname for the RBP being bootstrapped
#         otherwise variant prefixed with `pi-` is used
tmp/hostname: hostname
	@ grep "^[^#]" $< > $@ || { echo "pi-$(VARIANT)" > $@; }
	@ LC_ALL=C grep "^[a-z0-9_-]*$$" $@ > /dev/null || { echo "hostname can only contain lowercase alphanumeric characters, - and _."; exit 1; }

# If present, this key will be placed in `.ssh/authorized_keys` on Pi's first boot
tmp/id_rsa.pub:
	[ -f id_rsa.pub ] && cp id_rsa.pub $@ || { : > $@; }

# [recommended] If present, this key will be placed in `.ssh/authorized_keys` on Pi's first boot
tmp/id_ed25519.pub:
	[ -f id_ed25519.pub ] && cp id_ed25519.pub $@ || { : > $@; }

# verifies if version specified in `bitcoind-version` is available.
# If so, copies the file to `boot/`, otherwise errors.
tmp/bitcoind-version: bitcoind-version
	@curl -s https://api.github.com/repos/bitcoin/bitcoin/releases | jq -r '.[].tag_name' | grep -qx "$(shell cat $^)" && \
		{ echo "Bitcoin Core '$(shell cat $^)' found as a release"; exit 0; } || \
		curl -s https://api.github.com/repos/bitcoin/bitcoin/branches | jq -r '.[].name' | grep -qx "$(shell cat $^)" && \
			echo "Bitcoin Core '$(shell cat $^)' found as a branch" || { echo "Bitcoin Core version '$(shell cat $^)' not found in neither releases nor branches"; exit 0; }

	cp $< $@

tmp/bitcoin.conf: configs/bitcoin.conf
	cp $< $@

tmp/bitcoind.service: configs/bitcoind.service
	cp $< $@

tmp/sshd_config: configs/sshd_config
	cp $< $@

# This is the actual setup everything script
tmp/pi-setup.sh: variant-$(VARIANT)/pi-setup.sh
	cp $< $@

# This is a systemd service that ensures that `pi-setup.sh` runs only after network is available.
tmp/pi-setup.service: configs/pi-setup.service
	cp $< $@

# This systemd script ensures that `pi-setup.sh` runs only once and shutsdown the device when it's done
tmp/pi-shutdown.service: configs/pi-shutdown.service
	cp $< $@

tmp/torrc: configs/torrc
	cp $< $@


##
## Files specific to `VARIANT = zero`
##
tmp/bt-stuff.py: variant-zero/bt-stuff.py
	cp $< $@

tmp/bt-reconnect.sh: variant-zero/bt-reconnect.sh
	cp $< $@

tmp/bluetooth-MACs: variant-zero/bluetooth-MACs
	grep "^[^#]" $< > $@ || { : > $@; }

tmp/dhcpcd.conf: variant-zero/dhcpcd.conf
	cp $< $@

tmp/dnsmasq.conf: variant-zero/dnsmasq.conf
	cp $< $@

tmp/hostapd.conf: variant-zero/hostapd.conf
	cp $< $@


##
## Aggregate all files, including the variant-specific ones
##
boot/bundle.zip: tmp tmp/pi-setup.sh tmp/pi-setup.service tmp/pi-shutdown.service tmp/password tmp/hostname tmp/id_rsa.pub tmp/id_ed25519.pub tmp/bitcoind-version tmp/bitcoin.conf tmp/bitcoind.service tmp/sshd_config tmp/torrc $(VARIANT_DEPS)
	@ # These are needed because Makefile doesn't like prerequisites that don't exist…
	@ [ ! -s tmp/password ] && rm -f tmp/password || exit 0
	@ [ ! -s tmp/id_rsa.pub ] && rm -f tmp/id_rsa.pub || exit 0
	@ [ ! -s tmp/id_ed25519.pub ] && rm -f tmp/id_ed25519.pub || exit 0
	@
	zip -j $@ tmp/*
	@
	rm -rf tmp


##
## common files (to be placed in SD root)
##
boot/ssh:
	touch $@

# This is a script that will run on pi and bootstrap all the necessary basics
boot/run-once.sh: scripts/run-once.sh
	cp $< $@

boot/cmdline.txt.orig: /Volumes/boot/cmdline.txt
	cp $< $@

# Acquire WiFi credentials automatically
wpa_supplicant.automatic.conf:
	$(eval SSID := $(shell /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --getinfo | sed -n 's/^ *SSID: //p'))
	@ echo "$$WPA_SUPPLICANT" | \
		sed -e "s/<COUNTRY>/$(shell system_profiler -detailLevel mini SPAirPortDataType | grep -i "country code" | awk '{print $$3}')/" | \
		sed -e "s/<SSID>/$(SSID)/" | \
		sed -e "s/<PASSWORD>/$(shell security find-generic-password -wa '$(SSID)')/" > $@

# use `.gitignore`d `wpa_supplicant.automatic.conf`, if available, otherwise use `wpa_supplicant.conf`, if valid
boot/wpa_supplicant.conf: wpa_supplicant.conf
	@[ -f wpa_supplicant.automatic.conf ] && \
		{ cp wpa_supplicant.automatic.conf $@; echo "Using wpa_supplicant.automatic.conf"; exit 0; } || \
		{ grep -q 'COUNTRY\|SSID\|PASSWORD' $< && \
			{ \
				echo "ERROR: WiFi configuration is required"; \
				echo; \
				echo "Run below to get WiFi credentials for your current network used automatically:"; \
				echo "  make wpa_supplicant.automatic.conf"; \
				echo; \
				echo "NOTE: the command above will ask you for your username and password."; \
				echo "  hint: your username is $(shell whoami)"; \
				echo; \
				echo "Alternatively, open and edit '$<' file and replace:"; \
				echo "  <COUNTRY>, <SSID> and <PASSWORD> to match your network configuration"; \
				echo; \
				exit 1; \
			} || \
			{ cp $< $@; echo "Using $<"; exit 0; }; }


# ensure `boot/` contains everything that will be copied to the card
boot: $(PI_INIT3_FILES) boot/ssh boot/run-once.sh boot/cmdline.txt.orig boot/bundle.zip boot/wpa_supplicant.conf
	cp $(PI_INIT3_FILES) $@


write_image_to_sd_card: $(IMAGE)-raspbian-stretch-lite.img
	@ # Ensure that user passed correct `SD=<device>` parameter
	@[ ! -z "${SD}" ] || { \
		echo; \
		echo "ERROR: You have to pass your SD card device, ex:"; \
		echo "	make all SD=/dev/disk2"; \
		echo; \
		echo "If you're on MacOS, you check available devices with:"; \
		echo "	diskutil list"; \
		echo; \
		echo "WARNING: all data on the specified device will be"; \
		echo "         removed / deleted / nuked!"; \
		echo; \
		exit 1; \
	}
	@
	@ # Verify that the provided device exists and is a block device
	@[ -b "${SD}" ] || { \
		echo; \
		echo "ERROR: The value passed is not a block device:"; \
		echo "	SD=${SD}"; \
		echo; \
		echo "This script requires a valid and attached external"; \
		echo "block device, such as a microSD card, to bootstrap"; \
		echo "your Raspberry Pi Zero on."; \
		echo; \
		echo "If you're on MacOS, you check available devices with:"; \
		echo "	diskutil list"; \
		echo; \
		exit 1; \
	}
	@
	@ # Make sure that the requested device is unmounted before proceeding
	@ diskutil unmountDisk ${SD}
	@
	@ # Below line ensures that the user will be prompted for the password before proceeding
	@ sudo -K
	@
	@ echo
	@ echo "  Chosen device:"
	@ diskutil list ${SD} | awk '{print "    " $$0}'
	@ echo
	@ echo "  Your Raspberry Pi Zero will be bootstrapped on the"
	@ echo "  device specified above. Everything currently stored on it"
	@ echo "  will be deleted permanently. If you have verified that"
	@ echo "  it is the correct device, proceed by providing your"
	@ echo "  user account password below:"
	@ echo
	@ echo "  PROTIP: To see the progress of image copying, use key combo:"
	@ echo "  	 control+shift+t"
	@ echo
	@
	sudo dd bs=64m if=$< of=${SD}


# Ensure `/Volumes/boot` already exists or try to mount it if `SD` is provided & contains a block device
/Volumes/boot:
	@ [ -d /Volumes/boot ] && exit 0 || \
		{ \
			[ ! -z "${SD}" ] || { \
				echo "ERROR: $@ not available"; \
				echo; \
				echo "Either mount it or pass SD card device, ex:"; \
				echo "	make all SD=/dev/disk2"; \
				echo; \
				echo "If you're on MacOS, you check available devices with:"; \
				echo "	diskutil list"; \
				echo; \
				exit 1; \
			} \
		} && \
		[ -b "${SD}" ] || { \
			echo; \
			echo "ERROR: The value passed is not a block device:"; \
			echo "	SD=${SD}"; \
			echo; \
			echo "This script requires a valid and attached external"; \
			echo "block device, such as a microSD card, to bootstrap"; \
			echo "your Raspberry Pi Zero on."; \
			echo; \
			echo "If you're on MacOS, you check available devices with:"; \
			echo "	diskutil list"; \
			echo; \
			exit 1; \
		} && \
		diskutil quiet mountDisk ${SD} || { echo "unable to mount ${SD}…"; exit 1; } && \
		[ -d $@ ] && exit 0 || { \
			echo "ERROR: $@ still not available :("; \
			echo; \
			echo "You have successfully passed a path to a block device, however"; \
			echo "upon mounting, the necessary destination is still not available."; \
			echo; \
			echo "Make sure ${SD} points your SD card, and if you are sure"; \
			echo "it does, try writing image to your SD card again with:"; \
			echo "	make write_image_to_sd_card SD=${SD}"; \
			echo; \
			exit 1; \
		}


# do everything except writing the raspbian image. Can be run multiple times as long as card wasn't run in RBP yet
write_stuff_to_boot: pi-init3 boot /Volumes/boot
	cp boot/* /Volumes/boot/
	@
	@ [ ! -z "${SD}" ] && diskutil eject ${SD} || { echo "\n  NOTE: Manual eject is necessary, because device to unmount unknown ('SD=' not set)"; exit 0; }
	@
	@ echo
	@ echo "  All done :)"
	@ echo
	@ echo "  Next step is detaching the card from your computer an inserting it into"
	@ echo "  your Raspberry Pi Zero. The setup process there will take long hours"
	@ echo
	@ echo "  TODO: WRITE MOAR HERE"
	@ echo
	@ echo "  When the setup process is complete the device will automatically"
	@ echo "  turn off. You'll know it's off when the on-board LED is no longer lit."
	@
	@ # TODO: protip about password or ssh keys


all: clean write_image_to_sd_card write_stuff_to_boot


# Copy the Bitcoin blocks and chainstate directories from the computer to the raspberry pi
rsync: tmp tmp/hostname
	ssh "pi@$(shell cat tmp/hostname).local" 'mkdir -p /home/pi/.bitcoin'
	rsync -r ~/Library/Application\ Support/Bitcoin/{blocks,chainstate} "pi@$(shell cat tmp/hostname).local:/home/pi/.bitcoin/"


# NOTE: `pi-init3` needs to be here, otherwise Makefile thinks everything's done
.PHONY: clean all pi-init3 write_image_to_sd_card write_stuff_to_boot rsync
