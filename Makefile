wpa_supplicant.conf: wpa_supplicant.temp.conf
	# TODO: verify $< contains necessary info and create $@

bitcoind_version:
	# TODO: verify taht specified version actually exists

password:
	# TODO: strip comments before adding to zip

bundle.zip: bitcoin.conf bitcoind_version bitcoind.service password sshd_config torrc
	zip -j $@ $^


# TODO: how to pass microSD device


card: bundle.zip setup.sh


get_secrets:

.PHONY: card get_secrets
