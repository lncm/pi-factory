#!/bin/ash

setup_disk() {
	echo "Initializing EXT4 partition"
	/sbin/mkfs.ext4 -F /dev/mmcblk0p2
	echo "Mounting EXT4"
	/bin/echo "/dev/mmcblk0p2 /mnt ext4 noatime 0 0" >> /etc/fstab
	/bin/mount /mnt
}

create_swap() {
    echo "Create and install swap file"
    /bin/dd if=/dev/zero of=/mnt/var/cache/swap bs=1M count=1024 
    /bin/chown 600 /mnt/var/cache/swap
    /sbin/mkswap /mnt/var/cache/swap
    /sbin/swapon /mnt/var/cache/swap
    echo "Add swap to disk FSTAB"
    /bin/echo "/var/cache/swap none swap sw,pri=10 0 0" >> /mnt/etc/fstab
    echo "Enable swap at boot for drive"
    cd /mnt/etc/runlevels/boot || exit
    /bin/ln -s /etc/init.d/swap swap
}

clean_devs() {
    echo "Remove unused devices and mountpoints"
    /bin/sed -i '/cdrom/d' /mnt/etc/fstab
    /bin/rmdir /mnt/media/cdrom
    /bin/sed -i '/usbdisk/d' /mnt/etc/fstab
    /bin/rmdir /mnt/media/usb
    /bin/rmdir /mnt/media/floppy
}

partition_sd() {
    if [[ ! -e /dev/mmcblk0p2 ]]; then
	    echo "Partition doesn't exist, lets set it up"
        /usr/sbin/parted -s /dev/mmcblk0 mkpart p ext4 268M 100%
    else
        echo "Partition already exists!"
    fi
}

install_ext4() {
	/sbin/setup-disk -o /media/mmcblk0p1/box.apkovl.tar.gz /mnt || exit 1
	if [ ! -d /mnt/etc ]; then
		echo "Setup disk did not seem to create anything! Exiting"
		exit 1
	fi
}

setup_fat_fstab_ext4() {
	echo "Add FAT partition to new fstab"
	/bin/echo "/dev/mmcblk0p1 /media/mmcblk0p1 vfat defaults 0 0" >> /mnt/etc/fstab
}

check_mounted() {
	echo "Check if ext4 partition on SD is mounted"
	if [ ! -d /mnt/lost+found ]; then
		echo "Error: EXT4 partition doesn't seem to be mounted"
		exit 1
	fi
}

copy_wpa_supplicant() {
    echo "Copying network information to new mount"
    /bin/cp /etc/wpa_supplicant/wpa_supplicant.conf /mnt/etc/wpa_supplicant/wpa_supplicant.conf
}

setup_boot() {
    echo "Re-mount FAT partition read/write"
    /bin/mount -o remount,rw /dev/mmcblk0p1 /media/mmcblk0p1
    echo "Backup cmdline"
    /bin/cp /media/mmcblk0p1/cmdline.txt /media/mmcblk0p1/cmdline.txt.bak
    echo "Prepend root partition to boot command" 
    /bin/sed -e 's/^/root=\/dev\/mmcblk0p2 /' -i /media/mmcblk0p1/cmdline.txt
    echo "Remount FAT as read only"
    /bin/mount -o remount,ro /dev/mmcblk0p1 /media/mmcblk0p1
}

unmount_ext4_partition() {
    umount /mnt
}

# Steps
partition_sd
setup_disk
check_mounted
install_ext4 # setup file system
create_swap # setup swap
setup_fat_fstab_ext4 # Setup fstab for fat mount
copy_wpa_supplicant # Setup networking
clean_devs # Cleanup drives
setup_boot # Adjust fstab in main SD card

