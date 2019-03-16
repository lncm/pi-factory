from __future__ import absolute_import
from __future__ import division

from os import chdir, sys
from shutil import which
from subprocess import call
import fileinput
from configparser import ConfigParser, NoOptionError
from itertools import chain
import io


from plumbum import local

try:
    from plumbum.cmd import mkdir, docker, tail, cat, docker_compose, \
        git, diff, cp, rm, autossh, touch
except Exception as error:
    print(error)

# Alpine / Linux specific
try:
    from plumbum.cmd import lbu, apk, service
except Exception as error:
    print(error)

vcgencmd = local["/opt/vc/bin/vcgencmd"]


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


def get_kv(key, path):
    """
    Parse key-value config files and print out values

    :param key: left part of key value pair
    :param path: path to file
    :return: value of key
    """
    parser = ConfigParser(strict=False)
    with open(path) as lines:
        lines = chain(("[main]",), lines)   # workaround: prepend dummy section
        parser.read_file(lines)
        return parser.get('main', key)


def set_kv_parser(key, value, path, section="main"):
    """
    Parse key-value config files and write them out with a key-value change

    Note: comments are lost!

    :param key: left part of key value pair
    :param value: right part of key value pair
    :param path: path to file
    :param section: optional name of section to set in
    :return:
    """
    parser = ConfigParser(strict=False)
    with open(path) as lines:
        lines = chain(("[main]",), lines)   # workaround: prepend dummy section
        parser.read_file(lines)
        parser.set(section, key, value)
        data = io.StringIO()
        parser.write(data, space_around_delimiters=False)
        file = data.getvalue()
        lines = file.split("\n")
        with open(path, 'w') as file:
            file.write(str(lines[1:]))   # skip first section
            file.close()


def set_kv(key, value, path):
    """
    Set key to value in path
    kv pairs are separated by "="

    :param key:
    :param value:
    :param path:
    :return:
    """
    if not local.path(path).exists():
        # create file at path
        touch(path)
    current_val = None
    try:
        current_val = get_kv(key, path)
    except Exception as err:
        print(err)
    if value == current_val:
        # nothing to do
        print("%s already set to %s" % (key, value))
        return
    if current_val is None:
        # key does not exist yet
        with open(path, 'a') as file:
            # append kv pair to file
            file.write("\n%s=%s" % (key, value))
    else:
        with fileinput.FileInput(path, inplace=True, backup='.bak') as file:
            for line in file:
                print(line.replace(current_val, value), end='')


# def new_set_kv(key, value, path="/media/archive/archive/bitcoin_big/bitcoin.conf"):
#     key_search = key + "="
#     with open(path, 'r') as file:
#         data = file.readlines()
#         # print(data)
#         for line in data:
#             if key_search in line:
#                 print("Key found")
#                 split = line.split("=")
#                 if split[1] == value:
#                     print("Key already set to value")
#                 else:
#                     print("need to write changes")
#                     data.replace(split[1], value)
#                     with open(path, 'w') as file:
#                         file.write(data)
#                         file.close()
#
#
# def set_kv(key, value, path):
#     key_search = key + "="
#     with open(path, 'w') as f:
#         file = f.read()
#         for line in file:
#             if key_search in line:
#                 split = line.split("=")
#                 if split[1] == value:
#                     print("Key already set to value")
#                     pass
#                 else:
#                     print("Writing changes")
#                     file.replace(split[1], value)
#                     f.write(file)
#         f.close()


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
        # call(["docker", "exec", "compose_lnd_1", str(arguments)])
        docker("exec", "compose_lnd_1", arguments)
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


def tunnel(port, host):
    # Keep the tunnel open, no matter what
    while True:
        try:
            print("Tunneling local port 22 to " + host + ":" + port)
            port_str = "-R " + port + ":localhost:22"
            autossh("-M 0", "-o ServerAliveInterval=60", "-o ServerAliveCountMax=10", port_str, host)
        except Exception as error:
            print(error)


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


if __name__ == "__main__":
    print("This file is not meant to be run directly")

