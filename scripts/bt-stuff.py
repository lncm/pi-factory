#!/usr/bin/env python3

import signal
import sys
import dbus
import time
import pprint

from dbus.mainloop.glib import DBusGMainLoop

DBusGMainLoop(set_as_default=True)

iface_base = 'org.bluez'
iface_dev = '{}.Device1'.format(iface_base)
iface_adapter = '{}.Adapter1'.format(iface_base)
iface_props = 'org.freedesktop.DBus.Properties'

pp = pprint.PrettyPrinter(indent=2, depth=5)


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


def nearby_devices(known_devices):
    devices = []
    for path, device in get_manager().GetManagedObjects().items():
        adapter = device.get(iface_dev)
        if adapter is None:
            continue

        if adapter['Address'] in known_devices:
            devices.append(dbus.Interface(get_bus().get_object(iface_base, path), iface_dev))

    return devices if devices else None


def attempt_discovery(local_bluetooth_devices):
    #
    # METHOD #1: user pairs their PHONE with RBP
    #
    # put all BT devices into a discoverable & pairable mode for 4 hours
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
    for device in local_bluetooth_devices.values():
        device.StartDiscovery()

    time.sleep(10)

    for device in local_bluetooth_devices.values():
        device.StopDiscovery()


def main():
    # Help screen and some params passing
    import argparse
    p = argparse.ArgumentParser(description='BlueZ bluetooth PAN network server/client.')
    p.add_argument('remote_addr', nargs='+', help='BT MACs of all possible remote devices to connect to')
    p.add_argument('--pair', action='store_true', help='Launch in a pair mode')
    p.add_argument('-d', '--disconnect', action='store_true', help='Disconnect, if connected, and exit')
    p.add_argument('-r', '--reconnect', action='store_true', help='Reconnect, if connected, otherwise just connect')
    opts = p.parse_args()

    # setup logging
    global log
    import logging
    logging.basicConfig(level=logging.DEBUG)
    log = logging.getLogger()

    # @another_droog - you know what that is?
    signal.signal(signal.SIGTERM, lambda sig, frm: sys.exit(0))

    # find all local BT devices
    local_bluetooth_devices = {}
    bus = dbus.SystemBus()
    for path, ifaces in get_manager().GetManagedObjects().items():
        adapter = ifaces.get(iface_adapter)
        if adapter is None:
            continue

        device = dbus.Interface(bus.get_object(iface_base, path), iface_adapter)
        local_bluetooth_devices[prop_get(device, 'Address')] = device

    # ensure there's at least one _known_ device nearby
    nearby = nearby_devices(opts.remote_addr)
    if nearby is None:
        attempt_discovery(local_bluetooth_devices)

        nearby = nearby_devices(opts.remote_addr)
        if nearby is None:
            # TODO: no devices avail and no devices added
            return

    for device in nearby:
        log.debug('Using remote device: (addr: %s, name: %s)', prop_get(device, 'Address'), prop_get(device, 'Name'))

        try:
            device.ConnectProfile('nap')

        except:
            pass  # no idea why it fails sometimes, but still creates dbus interface

        net = dbus.Interface(device, 'org.bluez.Network1')

        if opts.disconnect or opts.reconnect:
            disconnect(net, device, opts.reconnect)

        if not opts.disconnect:
            connect(net, device)

    log.debug('Finished')


if __name__ == '__main__':
    sys.exit(main())
