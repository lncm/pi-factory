# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-18.04"

  config.vm.provision "shell", inline: <<-SHELL
        cp -R /vagrant/ /home/vagrant/host
        cd /home/vagrant/host
  	./make_img.sh
        cp lncm-workdir/lncm-box*.zip /vagrant/
        echo "You can find your lncm-box image in the current directory"
  SHELL
end
