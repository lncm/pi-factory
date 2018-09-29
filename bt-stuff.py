#!/usr/bin/env python3

import signal
import sys
import dbus
import time

from dbus.mainloop.glib import DBusGMainLoop

DBusGMainLoop(set_as_default=True)

iface_base = 'org.bluez'
iface_dev = '{}.Device1'.format(iface_base)
iface_adapter = '{}.Adapter1'.format(iface_base)
iface_props = 'org.freedesktop.DBus.Properties'


class BTError(Exception):
    pass


def get_bus():
    return dbus.SystemBus()


def get_manager():
    return dbus.Interface(get_bus().get_object(iface_base, '/'), 'org.freedesktop.DBus.ObjectManager')


def prop_get(obj, k, iface=None):
    if iface is None:
        iface = obj.dbus_interface

    return obj.Get(iface, k, dbus_interface=iface_props)


def prop_set(obj, k, v, iface=None):
    if iface is None:
        iface = obj.dbus_interface

    return obj.Set(iface, k, v, dbus_interface=iface_props)


def find_adapter(pattern=None):
    return find_adapter_in_objects(get_manager().GetManagedObjects(), pattern)


def find_adapter_in_objects(objects, pattern=None):
    bus, obj = get_bus(), None
    for path, ifaces in objects.items():
        adapter = ifaces.get(iface_adapter)
        if adapter is None:
            continue

        if not pattern or pattern == adapter['Address'] or path.endswith(pattern):
            obj = bus.get_object(iface_base, path)
            yield dbus.Interface(obj, iface_adapter)

    if obj is None:
        raise BTError('Bluetooth adapter not found')


def find_device(device_address, adapter_pattern=None):
    return find_device_in_objects(get_manager().GetManagedObjects(), device_address, adapter_pattern)


def find_device_in_objects(objects, device_address, adapter_pattern=None):
    bus = get_bus()
    path_prefix = ''
    if adapter_pattern:
        if not isinstance(adapter_pattern, str):
            adapter = adapter_pattern
        else:
            adapter = find_adapter_in_objects(objects, adapter_pattern)
        path_prefix = adapter.object_path

    for path, ifaces in objects.items():
        device = ifaces.get(iface_dev)
        if device is None: continue
        if device['Address'] == device_address and path.startswith(path_prefix):
            obj = bus.get_object(iface_base, path)
            return dbus.Interface(obj, iface_dev)

    raise BTError('Bluetooth device not found')


def disconnect(net, dev_remote, is_reconnect):
    try:
        net.Disconnect()

    except dbus.exceptions.DBusException as err:
        if is_reconnect and err.get_dbus_name() == 'org.bluez.Error.NotConnected':
            log.debug('No prior connection detected')
            return

        elif err.get_dbus_name() != 'org.bluez.Error.Failed':
            raise

        connected = prop_get(net, 'Connected')
        if connected:
            raise

    log.debug('Disconnected from network (dev_remote: %s, addr: %s), %s',
              dev_remote.object_path, prop_get(dev_remote, 'Address'),
              'by explicit ' + ('reconnect' if is_reconnect else 'disconnect') + ' command')


def connect(net, dev_remote):
    i_face = None
    try:
        i_face = net.Connect('nap')

    except dbus.exceptions.DBusException as err:
        if err.get_dbus_name() != 'org.bluez.Error.Failed':
            raise

        connected = prop_get(net, 'Connected')
        if not connected:
            raise

    if i_face is not None:
        log.debug('Connected to network (dev_remote: %s, addr: %s) with iface: %s',
                  dev_remote.object_path, prop_get(dev_remote, 'Address'), i_face)


def device_found(address, properties):
    print(address, properties)


def main():
    # Help screen and some params passing
    import argparse
    p = argparse.ArgumentParser(description='BlueZ bluetooth PAN network server/client.')
    p.add_argument('remote_addr', help='BT MAC of a remote device to connect to')
    p.add_argument('-d', '--disconnect', action='store_true', help='Disconnect, if connected, and exit.')
    p.add_argument('-r', '--reconnect', action='store_true', help='Reconnect, if connected, otherwise just connect')
    opts = p.parse_args()

    # setup logging
    global log
    import logging
    logging.basicConfig(level=logging.DEBUG)
    log = logging.getLogger()

    # @another_droog - you know what that is?
    signal.signal(signal.SIGTERM, lambda sig, frm: sys.exit(0))

    # discover all local BT devices
    local_bluetooth_devices = {}
    bus = dbus.SystemBus()
    for path, ifaces in get_manager().GetManagedObjects().items():
        adapter = ifaces.get(iface_adapter)
        if adapter is None:
            continue

        device = dbus.Interface(bus.get_object(iface_base, path), iface_adapter)
        local_bluetooth_devices[prop_get(device, 'Address')] = device

    #
    # METHOD #1: user pairs their PHONE with RBP
    #
    # put all BT devices into a discoverable & pairable mode for 4 hours
    # TODO: should only happen if no devices are paired/available…
    available_for_timeout = dbus.UInt32(4 * 60 * 60)
    for mac, device in local_bluetooth_devices.items():
        prop_set(device, 'Powered', True)
        prop_set(device, 'Discoverable', True)
        prop_set(device, 'DiscoverableTimeout', available_for_timeout)
        prop_set(device, 'Pairable', True)
        prop_set(device, 'PairableTimeout', available_for_timeout)

        log.debug('Putting local device into a discoverable mode (addr: %s): %s', mac, device.object_path)

    #
    # METHOD #2: RBP attempts to pair to a phone, if any MACs are provided
    #
    for mac, device in local_bluetooth_devices.items():
        # print(opts.remote_addr)
        device.StartDiscovery()
        device.connect_to_signal('DeviceFound', device_found)

        print(dir(device))
        # print(get_manager().GetManagedObjects())
        for a, b in get_manager().GetManagedObjects().items():
            print(a)
            print("")
            print(b)
            print("")
            print("")

    time.sleep(10)

    return








    dev_remote = find_device(opts.remote_addr, list(devs.values())[0])
    log.debug('Using remote device (addr: %s): %s', prop_get(dev_remote, 'Address'), dev_remote.object_path)

    try:
        dev_remote.ConnectProfile('nap')

    except:
        pass  # no idea why it fails sometimes, but still creates dbus interface

    net = dbus.Interface(dev_remote, 'org.bluez.Network1')

    if opts.disconnect or opts.reconnect:
        disconnect(net, dev_remote, opts.reconnect)

    if not opts.disconnect:
        connect(net, dev_remote)

    log.debug('Finished')


if __name__ == '__main__':
    sys.exit(main())
