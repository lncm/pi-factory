# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-18.04"

  config.vm.provision "shell", inline: <<-SHELL
  	cd /vagrant
  	git clone https://github.com/lncm/pi-factory
  	cd pi-factory
  	./make_img.sh
  SHELL
end
