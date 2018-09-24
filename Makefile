PI_INIT2_FILES=pi-init2/boot/cmdline.txt pi-init2/boot/pi-init2

2018-06-27-raspbian-stretch-lite.zip:
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
		{ curl -OJs "http://director.downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-06-29/$@" || rm -f $@; }; \
	}

# unzip raspbian image into an .img file
2018-06-27-raspbian-stretch-lite.img: 2018-06-27-raspbian-stretch-lite.zip
	@shasum -a 256 -c <<< "3271b244734286d99aeba8fa043b6634cad488d211583814a2018fc14fdca313  $<"
	@unzip -n $<

pi-init2:
	git submodule update --init --recursive

clean:
	rm -f boot/*

tmp:
	mkdir -p tmp

# If set, the contents of this file will be set as password for users `pi` & `root` on the Pi
tmp/password: password
	[ -f $< ] && grep "^[^#]" $< > $@ || { : > $@; }

# If present, this key will be placed in `.ssh/authorized_keys` on Pi's first boot
tmp/id_rsa.pub:
	[ -f id_rsa.pub ] && cp id_rsa.pub $@ || { : > $@; }

# [recommended] If present, this key will be placed in `.ssh/authorized_keys` on Pi's first boot
tmp/id_ed25519.pub:
	[ -f id_ed25519.pub ] && cp id_ed25519.pub $@ || { : > $@; }

# verifies if version specified in `bitcoind_version` is available.
# If so, copies the file to `boot/`, otherwise errors.
tmp/bitcoind_version: bitcoind_version
	@curl -s https://api.github.com/repos/bitcoin/bitcoin/releases | jq -r '.[].tag_name' | grep -qx "$(shell cat $^)" && \
		{ echo "Bitcoin Core '$(shell cat $^)' found as a release"; exit 0; } || \
		curl -s https://api.github.com/repos/bitcoin/bitcoin/branches | jq -r '.[].name' | grep -qx "$(shell cat $^)" && \
			echo "Bitcoin Core '$(shell cat $^)' found as a branch" || { echo "Bitcoin Core version '$(shell cat $^)' not found in neither releases nor branches"; exit 0; }

	cp $< $@

tmp/bitcoin.conf: bitcoin.conf
	cp $< $@

tmp/bitcoind.service: bitcoind.service
	cp $< $@

tmp/sshd_config: sshd_config
	cp $< $@

# This is the actual setup everything script
tmp/pi-setup.sh: pi-setup.sh
	cp $< $@

# This is a systemd service that ensures that `pi-setup.sh` runs only after network is available.
tmp/pi-setup.service: pi-setup.service
	cp $< $@

# This systemd script ensures that `pi-setup.sh` runs only once and shutsdown the device when it's done
tmp/pi-shutdown.service: pi-shutdown.service
	cp $< $@

tmp/torrc: torrc
	cp $< $@

tmp/bt-reconnect.sh: bt-reconnect.sh
	cp $< $@

tmp/bluetooth-MACs: bluetooth-MACs
	cp $< $@

boot/bundle.zip: tmp tmp/pi-setup.sh tmp/pi-setup.service tmp/pi-shutdown.service tmp/password tmp/id_rsa.pub tmp/id_ed25519.pub tmp/bitcoind_version tmp/bitcoin.conf tmp/bitcoind.service tmp/sshd_config tmp/torrc tmp/bt-reconnect.sh tmp/bluetooth-MACs
	@ # These are needed because Makefile doesn't like prerequisites that don't exist…
	@ [ ! -s tmp/password ] && rm -f tmp/password || exit 0
	@ [ ! -s tmp/id_rsa.pub ] && rm -f tmp/id_rsa.pub || exit 0
	@ [ ! -s tmp/id_ed25519.pub ] && rm -f tmp/id_ed25519.pub || exit 0
	@
	zip -j $@ tmp/*
	@
	rm -rf tmp

boot/ssh:
	touch $@

# This is a script that will run on pi and bootstrap all the necessary basics
boot/run-once.sh: run-once.sh
	cp $< $@

boot/cmdline.txt.orig: pi-init2/boot/cmdline.txt.stretch
	cp $< $@

boot/wpa_supplicant.conf: wpa_supplicant.conf
	@[ -f wpa_supplicant.private.conf ] && \
		{ cp wpa_supplicant.private.conf $@; echo "wpa_supplicant.private.conf copied to boot/"; exit 0; } || \
		{ grep -q 'COUNTRY\|SSID\|PASSWORD' $< && \
			{ echo "Please make sure you've set COUNTRY, SSID and PASSWORD in $< correctly"; exit 1; } || \
			{ cp $< $@; echo "$< copied to boot/"; exit 0; }; }

boot: $(PI_INIT2_FILES) boot/ssh boot/run-once.sh boot/cmdline.txt.orig boot/bundle.zip boot/wpa_supplicant.conf
	cp $(PI_INIT2_FILES) $@

write_image_to_sd_card: 2018-06-27-raspbian-stretch-lite.img
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

write_stuff_to_boot: pi-init2 boot /Volumes/boot
	cp boot/* /Volumes/boot/
	@
	@ [ ! -z "${SD}" ] && diskutil eject ${SD} || { echo "\n  NOTE: Manual eject is necessary, because device to unmount unknown ('SD=' not set)"; exit 0; }
	@
	@ echo
	@ echo "  All done :)"
	@ echo
	@ echo "  Next step is detaching the card from your computer an inserting it into"
	@ echo "  your Raspberry Pi Zero. The setup process there will take long hours"
	@ echo "  WRITE MOAR HERE"
	@ echo
	@ echo "  When the setup process is complete the device will automatically"
	@ echo "  turn off. You'll know it's off when the on-board LED is no longer lit."
	@
	@ # TODO: protip about password or ssh keys

all: clean write_image_to_sd_card write_stuff_to_boot

# NOTE: `pi-init2` needs to be here, otherwise Makefile things everything's done
.PHONY: clean all pi-init2 write_image_to_sd_card write_stuff_to_boot conclude
