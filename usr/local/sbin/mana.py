#!/usr/bin/env python3
"""mana.py Node Management

Usage:
  mana.py (info|start|stop|restart|logs|check|set_kv)
  mana.py (temp|freq|memory|voltage) [<device>]
  mana.py (backup|restore|source|diff|devtools|upgrade|full-upgrade|tunnel)
  mana.py bitcoind (start|stop|logs|info|fastsync|status|check|get_kv|set_conf) [<first>] [<second>] [--tail]
  mana.py lnd (start|stop|logs|info|create|unlock|connect|autoconnect|lncli|status|check|get_kv|set_kv) [<address>...] [<second>] [--tail]
  mana.py --selftest
  mana.py (-h|--help)
  mana.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.

"""
from __future__ import absolute_import
from __future__ import division

from mana import node

from os import chdir
from subprocess import call

from docopt import docopt
from plumbum import local

# TODO: bitcoind, lnd config 'getter' & "setter'

try:
    from plumbum.cmd import mkdir, docker_compose, tail, cat, docker_compose,\
        git, diff, cp, rm, autossh
except Exception as error:
    print(error)

# Alpine / Linux specific
try:
    from plumbum.cmd import lbu, apk, service
except Exception as error:
    print(error)

vcgencmd = local["/opt/vc/bin/vcgencmd"]

autoconnect_list = '/media/important/important/autoconnect.txt'


if __name__ == '__main__':
    args = docopt(__doc__, version='v0.4.2')
    if args['info']:
        bitcoind_info = docker_compose("exec", "compose_bitcoind_1", "bitcoin-cli", "-getinfo")
        lnd_info = docker_compose("exec", "compose_lnd_1", "lncli", "getinfo")
        # print(bitcoind_info, end='')
        # print(lnd_info, end='')
    elif args['start']:
        bitcoind_running = node.is_running("bitcoind")
        if bitcoind_running:
            print("bitcoind is already running")
        print("start unimplemented")
    elif args['stop']:
        # check and wait for clean shutdown
        bitcoind_running = node.is_running("bitcoind")
        lnd_running = node.is_running("lnd")

        while bitcoind_running or lnd_running:
            bitcoind_running = node.is_running("bitcoind")
            lnd_running = node.is_running("lnd")
            if bitcoind_running:
                # stop bitcoind
                print(docker_compose("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            if lnd_running:
                # stop lnd
                print(docker_compose("exec", "compose_lnd_1", "lncli", "stop"))
        # now we can safely stop
        service("docker-compose", "stop")
    elif args['restart']:
        # check and wait for clean shutdown
        bitcoind_running = node.is_running("bitcoind")
        if node.is_running("bitcoind"):
            print("bitcoind is running")
        print("bitcoind is not running")
        lnd_running = node.is_running("lnd")
        if node.is_running("lnd"):
            print("lnd is running")
        print("lnd is not running")
        while bitcoind_running or lnd_running:
            if bitcoind_running:
                # stop bitcoind
                print(docker_compose("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            if lnd_running:
                # stop lnd
                print(docker_compose("exec", "compose_lnd_1", "lncli", "stop"))
        # now we can safely restart
        service("docker-compose", "restart")
    elif args['logs']:
        print(tail("/var/log/messages"))
    elif args['temp']:
        print(node.temp())
    elif args['voltage']:
        print(node.voltage(args['<device>']))
    elif args['freq']:
        print(node.freq(args['<device>']))
    elif args['memory']:
        print(node.memory(args['<device>']))
    elif args['backup']:
        lbu("pkg", "-v", "/media/important/important/")
    elif args['restore']:
        print("restore unimplemented")
    elif args['start']:
        service("docker-compose", "start")
    elif args['source']:
        node.install_git()
        node.get_source()
    elif args['set_conf']:
        node.set_kv('<first>', '<second>')
    elif args['full-upgrade']:
        # Replaces entire FAT contents,
        # as if we installed from freshly burned SD card
        print("Warning: this will reinstall the latest version")
        if args['--confirm']:
            print("Starting upgrade...")
            node.install_git()
            node.get_source()
            chdir("/home/lncm/pi-factory")
            git("pull")
            call(["make_upgrade.sh"])
        else:
            print("Use --confirm to start the process")
    elif args['diff']:
        node.do_diff()
    elif args['upgrade']:
        node.upgrade()
    elif args['tunnel']:
        node.tunnel()
    elif args['check']:
        """check box filesystem structure"""
        archive_exists = local.path("/media/archive/archive").exists()
        important_exists = local.path("/media/important/important").exists()
        volatile_exists = local.path("/media/volatile/volatile").exists()

        if not archive_exists:
            print("archive usb device is missing")
        if not important_exists:
            print("important usb device is missing")
        if not volatile_exists:
            print("volatile usb device is missing")
    elif args['devtools']:
        apk("update")
        apk("add", "tmux", "sudo", "git", "rsync", "htop", "iotop", "nmap", "nano")
    elif args['bitcoind']:
        if args['start']:
            bitcoind_running = node.is_running("bitcoind")
            if bitcoind_running:
                print("bitcoind is running already")
            print("bitcoin start not implemented yet")
        elif args['stop']:
            bitcoind_running = node.is_running("bitcoind")
            if bitcoind_running:
                print(docker_compose("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            else:
                print("bitcoind is already stopped")
        elif args['logs']:
            node.logs("/media/volatile/volatile/bitcoin/debug.log", args["--tail"], "bitcoind")
        elif args['info']:
            docker_compose("exec", "compose_bitcoind_1", "bitcoin-cli", "-getinfo")
        elif args['fastsync']:
            node.fastsync()
        elif args['check']:
            """check bitcoind filesystem structure"""
            bitcoind_dir = local.path("/media/archive/archive/bitcoin").exists()
            if not bitcoind_dir:
                print("bitcoin folder missing")
            bitcoind_conf = local.path("/media/archive/archive/bitcoin/bitcoin.conf").exists()
            if not bitcoind_conf:
                print("bitcoin.conf missing")
        elif args['status']:
            bitcoind_running = node.is_running("bitcoind")
            if node.is_running("bitcoind"):
                print("bitcoind is running")
            print("bitcoind is not running")
        elif args['set_kv']:
            node.set_kv(args['<first>'], args['<second>'], "/media/archive/archive/bitcoin_big/bitcoin.conf")
        elif args['get_kv']:
            node.get_kv(args['<first>'], "/media/archive/archive/bitcoin_big/bitcoin.conf")
    elif args['lnd']:
        if args['start']:
            lnd_running = node.is_running("lnd")
            if lnd_running:
                print("lnd is already running")
            print("lnd start not implemented yet")
        elif args['stop']:
            lnd_running = node.is_running("lnd")
            if lnd_running:
                call(["docker", "exec", "compose_lnd_1", "lncli", "stop"])
            print("lnd is already stopped")
        elif args['connect']:
            print(node.lnd_connect(args['<address>']))
        elif args['autoconnect']:
            node.autoconnect(autoconnect_list)
        elif args['lncli']:
            command = args['<address>']
            node.lncli(command)
        elif args['logs']:
            node.logs("/media/volatile/volatile/lnd/logs/bitcoin/mainnet/lnd.log", args['--tail'], "lnd")
        elif args['info']:
            docker_compose("exec", "compose_lnd_1", "lncli", "getinfo")
        elif args['create']:
            # TODO: Inline create wallet script
            # This will either import an existing seed (or our own generated one),
            # or use LND to create one.
            # It will also create a password either randomly or use an existing password provided)
            call(["/usr/local/sbin/lncm-createwallet.py"])
        elif args['unlock']:
            # manually unlock lnd wallet
            print(node.lnd_cmd("lncli", "unlock", args['<address>']))
        elif args['status']:
            lnd_running = node.is_running("lnd")
            if node.is_running("lnd"):
                print("lnd is running")
            print("lnd is not running")
        elif args['check']:
            """check lnd filesystem structure"""
            lnd_dir = local.path("/media/important/important/lnd").exists()
            if not lnd_dir:
                print("lnd folder missing")
            lnd_conf = local.path("/media/important/important/lnd/lnd.conf").exists()
        elif args['set_kv']:
            node.set_kv(args['<address>'], args['<second>'], "/media/important/important/lnd/lnd.conf")
        elif args['get_kv']:
            node.get_kv(args['<address'], "/media/important/important/lnd/lnd.conf")
    elif args['--selftest']:
        print("run mana.py")
        call(["mana.py"])
        print("run mana.py --version")
        call(["mana.py", "--version"])
        print("run mana.py --help")
        call(["mana.py", "--help"])
        box_args = ["start", "stop", "restart", "temp", "freq", "memory", "info",
                    "logs", "voltage", "backup", "restore", "devtools"]
        lnd_args = ["start", "stop", "logs", "info", "create", "unlock", "connect",
                    "autoconnect", "lncli"]
        bitcoind_args = ["start", "stop", "logs", "info", "fastsync"]
        for arg in box_args:
            print("run mana.py " + arg)
            call(["mana.py", arg])
        for arg in lnd_args:
            print("run mana.py lnd " + arg)
            call(["mana.py", "lnd", arg])
        for arg in bitcoind_args:
            print("mana.py bitcoind " + arg)
            call(["mana.py", "bitcoind", arg])
