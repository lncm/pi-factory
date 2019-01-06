#!/usr/bin/env python3
# Copyright 2018 LNCM contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import glob
import re

# TODO: handle mountable devices without partitions!

usb_dev_pattern = ['sd.*']
usb_part_pattern = ['sd.[1-9]*']
sd_dev_pattern = ['mmcblk*']
sd_part_pattern = ['mmcblk.p[1-9]*']

def dev_size(device):
    # return device size in bytes
    path = '/sys/block/'
    num_sectors = open(path + device + '/size').read().rstrip('\n')
    sector_size = open(path + device + '/queue/hw_sector_size').read().rstrip('\n')
    return (int(num_sectors)*int(sector_size))


def usb_part_size(partition):
    # return partition size in bytes
    path = '/sys/block/'
    device = partition[:-1]
    num_sectors = open(path + device + '/' + partition + '/size').read().rstrip('\n')
    sector_size = open(path + device + '/queue/hw_sector_size').read().rstrip('\n')
    return (int(num_sectors)*int(sector_size))


def sd_part_size(partition):
    # return partition size in bytes
    path = '/sys/block/'
    device = partition[:-2]
    num_sectors = open(path + device + '/' + partition + '/size').read().rstrip('\n')
    sector_size = open(path + device + '/queue/hw_sector_size').read().rstrip('\n')
    return (int(num_sectors)*int(sector_size))


def usb_devs():
    devices = []
    for device in glob.glob('/sys/block/*'):
        for pattern in usb_dev_pattern:
            if re.compile(pattern).match(os.path.basename(device)):
                devices.append(os.path.basename(device))
    return devices


def sd_devs():
    devices = []
    for device in glob.glob('/sys/block/*'):
        for pattern in sd_dev_pattern:
            if re.compile(pattern).match(os.path.basename(device)):
                devices.append(os.path.basename(device))
    return devices


def usb_partitions():
    partitions = []
    for device in usb_devs():
        # print('device: ' + str(device))
        for partition in glob.glob('/sys/block/' + str(device) + '/*'):
            for pattern in usb_part_pattern:
                # print('pattern: ' + str(pattern))
                if re.compile(pattern).match(os.path.basename(partition)):
                    partitions.append(os.path.basename(partition))
    return partitions


def sd_partitions():
    partitions = []
    for device in sd_devs():
        for partition in glob.glob('/sys/block/' + str(device) + '/*'):
            for pattern in sd_part_pattern:
                if re.compile(pattern).match(os.path.basename(partition)):
                    partitions.append(os.path.basename(partition))
    return partitions


def usb_partition_table():
    table = {}
    for partition in usb_partitions():
        table[partition] = int(usb_part_size(partition))
    return table

def sd_partition_table():
    table = {}
    for partition in sd_partitions():
        table[partition] = sd_part_size(partition)
    return table


def sd_device_table():
    table = {}
    for device in sd_devs():
        table[device] = dev_size(device)
    return table


def usb_device_table():
    table = {}
    for device in usb_devs():
        table[device] = dev_size(device)
    return table


def sort_partitions():
    # sort partitions from smallest to largest
    usb_partitions = usb_partition_table()
    sorted_partitions = sorted(usb_partitions.items(), key=lambda x: x[1])
    return sorted_partitions


def largest_usb_partition():
    usb_partitions = sort_partitions()
    last = len(usb_partitions) - 1
    largest = usb_partitions[last]
    return str(largest[0])


def smallest_usb_partition():
    usb_partitions = sort_partitions()
    smallest = usb_partitions[0]
    return str(smallest[0])


def medium_usb_partition():
    usb_partitions = sort_partitions()
    usb_partitions.pop(0) # remove smallest
    usb_partitions.pop(len(usb_partitions) - 1) # remove largest
    return str(usb_partitions[0][0])


def largest_usb_part_size():
    return usb_part_size(largest_usb_partition())


def uuid_table():
    device_table = os.popen('blkid').read().splitlines()
    devices = {}
    for device in device_table:
        dev = device.split(":")[0].split("/")[2]
        uuid = device.split('"')[1]
        devices[dev] = uuid
    return devices


def get_uuid(device):
    uuids = uuid_table()
    return str(uuids[device])



# print("Detected storage devices:")
# print('usb devs: ' + str(sorted(usb_devs())))
# print('usb partitions: ' + str(sorted(usb_partitions())))
# print()
# print('sd devices: ' + str(sorted(sd_devs())))
# print('sd partitions: ' + str(sorted(sd_partitions())))
# print()
# print('usb partition table: ' + str(sorted(usb_partition_table().items())))
# print('usb device table: ' + str(sorted(usb_device_table())))
# print()
# print('sd partition table: ' + str(sorted(sd_partition_table())))
# print('sd device table: ' + str(sorted(sd_device_table())))
# print()
# print('largest usb partition: ' + str(largest_usb_partition()))
# print('medium usb partition: ' + str(medium_usb_partition()))
# print('smallest usb partition: ' + str(smallest_usb_partition()))
# print('largest usb partition size: ' + str(largest_usb_part_size()))

def main():
    print('Starting USB installation')
    print('Using ' + largest_usb_partition() + ' as archive storage')
    print('Using ' + medium_usb_partition() + ' as volatile storage')
    print('Using ' + smallest_usb_partition() + ' as important storage')
    largest = largest_usb_partition()
    medium = medium_usb_partition()
    smallest = smallest_usb_partition()
    os.system('/usr/local/sbin/lncm-usb '+largest+' '+medium+' '+smallest+' '+get_uuid(largest)+' '+get_uuid(medium)+' '+get_uuid(smallest)+' '+str(largest_usb_part_size()))


if __name__ == '__main__':
    main()