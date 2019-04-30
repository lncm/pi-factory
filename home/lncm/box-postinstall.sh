#!/bin/sh

## LNCM-Box post-installation script

# To be run on persistently installed SD card
# This script will only run once, to complete post-installation

REQUIREMENTS_URL=https://raw.githubusercontent.com/lncm/noma/master/requirements.txt

is_installed() {
	if [ -f /media/mmcblk0p1/installed ]; then
		return 0
	else
		return 1
	fi
}

update_pip_pkg() {
	echo "Update python package $1"
	while ! [ "$(/usr/bin/pip3 install --upgrade $1)" ]; do
		update_pip_pkg $1
	done
}

install_apk() {
	echo "Install $1"
	while [ -z "$(apk -e info $1)" ]; do
		/sbin/apk add $1
	done
}

install_noma_requirements() {
	echo "Install noma requirements"
	if [ "$(/usr/bin/pip3 install -r $REQUIREMENTS_URL)" ]; then
		echo "Requirements installed successfully"
	else
		install_noma_requirements
	fi
}

install_python() {
	install_apk python3
}

install_apk_deps() {
	echo "Install misc dependencies"
	install_apk py3-psutil
}

install_pip() {
	echo "Install and upgrade pip"
	update_pip_pkg pip
}

install_pip_pkg() {
	echo "Install python package $1"
	while [ -z "$(/usr/bin/pip3 show $1)" ]; do
		/usr/bin/pip3 install $1
	done
}

build_noma() {
	echo "Building noma - node management tools from source"
	install_apk gcc
	install_apk python3-dev
	install_apk linux-headers
	install_apk py-configobj
	install_apk libusb
	install_apk python-dev
	install_apk musl-dev
	/usr/bin/wget https://github.com/lncm/noma/archive/master.zip
	/usr/bin/unzip master.zip
	/usr/bin/pip3 install -r https://raw.githubusercontent.com/lncm/noma/master/requirements.txt
	install_pip_pkg wheel
	cd noma-master
	/usr/bin/python3 setup.py bdist_wheel
	/usr/bin/pip3 install dist/noma-*.whl
}

install_python_deps() {
	echo "Install python dependencies"
	install_pip_pkg docker
}

install_noma() {
	echo "Install noma - node management tool"
	while [ -z "$(/usr/bin/pip3 show noma)" ]; do
		/usr/bin/pip3 install noma
	done
}

run_noma() {
	echo "Running noma box-install"
	/usr/bin/noma install-box >/var/log/noma.log 2>&1 &
}

main() {
	if ! is_installed; then
		echo "Error: LNCM installation not found!"
		exit 1
	fi

	install_python
	#install_python_deps
	install_apk_deps
	install_pip
	#install_noma_requirements
	install_noma
	#build_noma
	run_noma
}

main
