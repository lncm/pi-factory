#!/usr/bin/env python3
"""mana.py Node Management

Usage:
  mana.py (info|start|stop|restart|logs)
  mana.py (temp|clock|memory|voltage) [<device>]
  mana.py (backup|restore|source|diff|devtools|upgrade|full-upgrade)
  mana.py bitcoind (start|stop|logs|info|fastsync|status) [--tail]
  mana.py lnd (start|stop|logs|info|create|unlock|connect|autoconnect|lncli|status) [<address>...] [--tail]
  mana.py --selftest
  mana.py (-h|--help)
  mana.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.

"""
from __future__ import absolute_import
from __future__ import division

from os import chdir, sys
from shutil import which
from subprocess import call

from docopt import docopt
from plumbum import local

try:
    from plumbum.cmd import mkdir, docker, tail, cat, docker_compose,\
        git, diff, cp, rm
except Exception as error:
    print(error)

# Alpine / Linux specific
try:
    from plumbum.cmd import lbu, apk, service
except Exception as error:
    print(error)

vcgencmd = local["/opt/vc/bin/vcgencmd"]

autoconnect_list = '/media/important/important/autoconnect.txt'


def fastsync():
    """
    download blocks and chainstate snapshot

    :return:
    """
    bitcoin_dir = "/media/archive/archive/bitcoin/"
    location = "http://utxosets.blob.core.windows.net/public/"
    snapshot = "utxo-snapshot-bitcoin-mainnet-565305.tar"
    url = location + snapshot
    bitcoin_path = local.path(bitcoin_dir)
    print("Checking if snapshot archive exists")
    if bitcoin_path.exists():
        print("Bitcoin directory exists")
        if local.path(bitcoin_dir + snapshot).exists():
            print("Snapshot archive exists")
            if local.path(bitcoin_dir + "blocks").exists():
                print("Bitcoin blocks directory exists, exiting")
                sys.exit(1)
            else:
                # Assumes download was interrupted
                print("Continue downloading snapshot")
                call(["wget", "-c", url])
                call(["tar", "xvf", snapshot])
    else:
        print("Bitcoin directory does not exist, creating")
        if local.path("/media/archive/archive").exists():
            mkdir(bitcoin_dir)
            chdir(bitcoin_dir)
            call(["wget", "-c", url])
            call(["tar", "xvf", snapshot])
        else:
            print("Error: archive directory does not exist on your usb device")
            print("Are you sure it was installed correctly?")
            sys.exit(1)


def is_running(node=''):
    """check if lnd or bitcoind are running"""
    docker_ps = local["docker", "ps"]
    node_string = "compose_" + node + "_1"
    if node:
        grep = local["grep", "-c", node_string]
    else:
        grep = local["grep", "-c", "compose_lnd_1"]
    running = docker_ps() | grep()
    return bool(running)


def lnd_connect(node=""):
    """
    let lnd connect to pubkey @ host : port

    :node: pubkey @ host : port
    :return: result
    """
    try:
        if node:
            lnd_cmd("lncli", "connect", node)
        else:
            lnd_cmd("lncli", "connect")
    except Exception as error:
        print(error)


def bitcoind_cmd(*arguments):
    try:
        docker("exec", "compose_bitcoind_1", arguments)
    except Exception as error:
        print(error)


def lnd_cmd(*arguments):
    try:
        call(["docker", "exec", "compose_lnd_1", str(arguments)])
    except Exception as error:
        print(error)


def voltage(device=""):
    """
    chip voltage (default: core)

    :param device: core, sdram_c, sdram_i, sdram_p
    :return: voltage
    """
    return vcgencmd("measure_volts", device).strip("\n")


def temp():
    """
    :return: cpu temperature
    """
    cpu_temp = cat("/sys/class/thermal/thermal_zone0/temp")
    return str(int(cpu_temp) / 1000) + "C"


def clock(device=""):
    """
    chip clock (default: arm)

    :device: arm, core, h264, isp, v3d, uart, pwm, emmc, pixel, vec, hdmi, dpi
    :return: frequency
    """
    if device:
        return vcgencmd("measure_clock", device).strip("\n")
    return vcgencmd("measure_clock", "arm").strip("\n")


def memory(device=""):
    """
    memory allocation split between cpu and gpu

    :param device: arm, gpu
    :return: memory allocated
    """
    if device:
        return vcgencmd("get_mem", device).strip("\n")
    return vcgencmd("get_mem", "arm").strip("\n")


def autoconnect(autoconnect_path):
    print("Connecting to:")
    with open(autoconnect_path) as address_list:
        for address in address_list:
            print(address.strip())
            lnd_connect(address.strip())


def logs(path, tail_on, node):
    if tail_on:
        print(tail(path))
    else:
        chdir("/home/lncm/compose")
        if node:
            container_name = "compose_" + node + "_1"
            docker_compose("logs", "-f", container_name)
        else:
            # default to bitcoind if node not given
            docker_compose("logs", "-f", "compose_bitcoind_1")


def lncli(argument):
    if argument:
        call(["docker", "exec", "compose_lnd_1", "lncli", argument])
    else:
        call(["docker", "exec", "compose_lnd_1", "lncli"])


def install_git():
    if which("git"):
        pass
    else:
        apk("update")
        apk("add", "git")


def get_source():
    factory_path = local.path("/home/lncm/pi-factory")
    if factory_path.exists():
        print("source directory already exists")
        print("going to update with git pull")
        chdir("/home/lncm/pi-factory")
        git("pull")
    else:
        chdir("/home/lncm")
        git("clone", "https://github.com/lncm/pi-factory.git")


def upgrade():
    """Regenerate box.apkovl.tar.gz and mark SD as uninstalled"""
    install_git()
    get_source()
    chdir("/home/lncm/pi-factory")
    git("pull")
    print("Migrating current WiFi credentials")
    supplicant_sd = local.path("/etc/wpa_supplicant/wpa_supplicant.conf")
    supplicant_gh = local.path("etc/wpa_supplicant/wpa_supplicant.conf")
    cp("-v", supplicant_sd, supplicant_gh)
    call(["./make_apkovl.sh"])
    call(["mount", "-o", "remount,ro", "/dev/mmcblk0p1", "/media/mmcblk0p1"])
    cp("-v", "box.apkovl.tar.gz", "/media/mmcbkl0p1")
    rm("-v", "/media/mmcblk0p1/installed")
    call(["mount", "-o", "remount,ro", "/dev/mmcblk0p1", "/media/mmcblk0p1"])
    print("Done")
    print("Please reboot to upgrade your box")


def do_diff():
    install_git()
    factory = local.path("/home/lncm/pi-factory")

    def make_diff():
        print("Generating /home/lncm/etc.diff")
        diff("-r", "etc", "/home/lncm/pi-factory/etc")
        print("Generating /home/lncm/usr.diff")
        diff("-r", "usr", "/home/lncm/pi-factory/usr")
        print("Generating /home/lncm/home.diff")
        diff("-r", "home", "/home/lncm/pi-factory/home")

    if factory.exists():
        chdir("/home/lncm/pi-factory")
        print("Getting latest sources")
        git("pull")
        make_diff()
    else:
        get_source()
        make_diff()


if __name__ == '__main__':
    args = docopt(__doc__, version='v0.4.1')
    if args['info']:
        bitcoind_info = docker("exec", "compose_bitcoind_1", "bitcoin-cli", "-getinfo")
        lnd_info = docker("exec", "compose_lnd_1", "lncli", "getinfo")
        # print(bitcoind_info, end='')
        # print(lnd_info, end='')
    if args['start']:
        bitcoind_running = is_running("bitcoind")
        if bitcoind_running:
            print("bitcoind is already running")
        print("start unimplemented")
    if args['stop']:
        # check and wait for clean shutdown
        bitcoind_running = is_running("bitcoind")
        lnd_running = is_running("lnd")

        while bitcoind_running or lnd_running:
            bitcoind_running = is_running("bitcoind")
            lnd_running = is_running("lnd")
            if bitcoind_running:
                # stop bitcoind
                print(docker("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            if lnd_running:
                # stop lnd
                print(docker("exec", "compose_lnd_1", "lncli", "stop"))
        # now we can safely stop
        service("docker-compose", "stop")
    if args['restart']:
        # check and wait for clean shutdown
        bitcoind_running = is_running("bitcoind")
        if is_running("bitcoind"):
            print("bitcoind is running")
        print("bitcoind is not running")
        lnd_running = is_running("lnd")
        if is_running("lnd"):
            print("lnd is running")
        print("lnd is not running")
        while bitcoind_running or lnd_running:
            if bitcoind_running:
                # stop bitcoind
                print(docker("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            if lnd_running:
                # stop lnd
                print(docker("exec", "compose_lnd_1", "lncli", "stop"))
        # now we can safely restart
        service("docker-compose", "restart")
    if args['logs']:
        print(tail("/var/log/messages"))
    if args['temp']:
        print(temp())
    elif args['voltage']:
        print(voltage(args['<device>']))
    elif args['clock']:
        print(clock(args['<device>']))
    elif args['memory']:
        print(memory(args['<device>']))
    elif args['backup']:
        lbu("pkg", "-v", "/media/important/important/")
    elif args['restore']:
        print("restore unimplemented")
    elif args['start']:
        service("docker-compose", "start")
    elif args['source']:
        install_git()
        get_source()
    elif args['full-upgrade']:
        # Replaces entire FAT contents,
        # as if we installed from freshly burned SD card
        print("Warning: this will reinstall the latest version")
        if args['--confirm']:
            print("Starting upgrade...")
            install_git()
            get_source()
            chdir("/home/lncm/pi-factory")
            git("pull")
            call(["make_upgrade.sh"])
        else:
            print("Use --confirm to start the process")
    elif args['diff']:
        do_diff()
    elif args['upgrade']:
        upgrade()
    elif args['devtools']:
        apk("update")
        apk("add", "tmux", "sudo", "git", "rsync", "htop", "iotop", "nmap", "nano")
    elif args['bitcoind']:
        if args['start']:
            bitcoind_running = is_running("bitcoind")
            if bitcoind_running:
                print("bitcoind is running already")
            print("bitcoin start not implemented yet")
        elif args['stop']:
            bitcoind_running = is_running("bitcoind")
            if bitcoind_running:
                print(docker("exec", "compose_bitcoind_1", "bitcoin-cli", "stop"))
            else:
                print("bitcoind is already stopped")
        elif args['logs']:
            logs("/media/volatile/volatile/bitcoin/debug.log", args["--tail"], "bitcoind")
        elif args['info']:
            docker("exec", "compose_bitcoind_1", "bitcoin-cli", "-getinfo")
        elif args['fastsync']:
            fastsync()
        elif args['status']:
            bitcoind_running = is_running("bitcoind")
            if is_running("bitcoind"):
                print("bitcoind is running")
            print("bitcoind is not running")
    elif args['lnd']:
        if args['start']:
            lnd_running = is_running("lnd")
            if lnd_running:
                print("lnd is already running")
            print("lnd start not implemented yet")
        elif args['stop']:
            lnd_running = is_running("lnd")
            if lnd_running:
                call(["docker", "exec", "compose_lnd_1", "lncli", "stop"])
            print("lnd is already stopped")
        elif args['connect']:
            print(lnd_connect(args['<address>']))
        elif args['autoconnect']:
            autoconnect(autoconnect_list)
        elif args['lncli']:
            command = args['<address>']
            lncli(command)
        elif args['logs']:
            logs("/media/volatile/volatile/lnd/logs/bitcoin/mainnet/lnd.log", args['--tail'], "lnd")
        elif args['info']:
            docker("exec", "compose_lnd_1", "lncli", "getinfo")
        elif args['create']:
            # TODO: Inline create wallet script
            # This will either import an existing seed (or our own generated one),
            # or use LND to create one.
            # It will also create a password either randomly or use an existing password provided)
            call(["/usr/local/sbin/lncm-createwallet.py"])
        elif args['unlock']:
            # manually unlock lnd wallet
            print(lnd_cmd("lncli", "unlock", args['<address>']))
        elif args['status']:
            lnd_running = is_running("lnd")
            if is_running("lnd"):
                print("lnd is running")
            print("lnd is not running")
    elif args['--selftest']:
        print("run mana.py")
        call(["mana.py"])
        print("run mana.py --version")
        call(["mana.py", "--version"])
        print("run mana.py --help")
        call(["mana.py", "--help"])
        box_args = ["start", "stop", "restart", "temp", "clock", "memory", "info",
                    "logs", "voltage", "backup", "restore", "devtools"]
        lnd_args = ["start", "stop", "logs", "info", "create", "unlock", "connect",
                    "autoconnect", "lncli"]
        bitcoind_args = ["start", "stop", "logs", "info", "fastsync"]
        for arg in box_args:
            print("run mana.py box " + arg)
            call(["mana.py", "box", arg])
        for arg in lnd_args:
            print("run mana.py lnd " + arg)
            call(["mana.py", "lnd", arg])
        for arg in bitcoind_args:
            print("mana.py bitcoind " + arg)
            call(["mana.py", "bitcoind", arg])
