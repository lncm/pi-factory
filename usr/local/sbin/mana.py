"""mana.py Node Management

Usage:
  mana.py box (start|stop|temp|voltage)
  mana.py bitcoin (start|stop|logs|info) [--tail]
  mana.py lnd (start|stop|logs|info|create|unlock) [--tail]
  mana.py (-h | --help)
  mana.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.

"""
from docopt import docopt

from subprocess import call
from os import chdir

from plumbum import local
from plumbum.cmd import grep, wc, cat, head

# TODO: source, full-upgrade, upgrade, diff, devtools,
# devtools

if __name__ == '__main__':
    arguments = docopt(__doc__, version='v0.4.1')
    print(arguments)
    if arguments['box'] == True:
      if arguments['temp'] == True:
        # CPU temperature
        cpu_temp = call(["cat", "/sys/class/thermal/thermal_zone0/temp"])
        print(str(cpu_temp/1000) + "C")
      elif arguments['start'] == True:
        call(["service", "docker-compose", "start"])
      elif arguments['devtools'] == True:
        call(["apk", "update"])
        call(["apk", "add", "tmux", "sudo", "git", "rsync", "htop", "iotop", "nmap", "nano"])
      elif arguments['stop'] == True:
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "stop"])
        call(["docker", "exec", "-it", "compose_bitcoind_1", "bitcoin-cli", "stop"])
        call(["service", "docker-compose", "stop"])
      elif arguments['restart'] == True:
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "stop"])
        call(["docker", "exec", "-it", "compose_bitcoind_1", "bitcoin-cli", "stop"])
        # TODO: wait and check for clean shutdown
        call(["service", "docker-compose", "restart"])
      elif arguments['logs'] == True:
        call(["tail", "-f", "/var/log/messages"])
      elif arguments['info'] == True:
        chdir("/home/lncm/compose")
        call(["docker", "exec", "-it", "compose_bitcoind_1", "bitcoin-cli", "-getinfo"])
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "getinfo"])
    elif arguments['bitcoin'] == True:
      if arguments['start'] == True:
        print("bitcoin start not implemented yet")
      elif arguments['stop'] == True:
        call(["docker", "exec", "-it", "compose_bitcoind_1", "bitcoin-cli", "stop"])
      elif arguments['logs'] == True:
        chdir("/home/lncm/compose")
        call(["docker-compose", "logs", "-f", "compose_bitcoind_1"])
        if arguments['--tail'] == True:
          call(["tail", "-f", "/media/volatile/volatile/bitcoin/debug.log"])
      elif arguments['info'] == True:
        call(["docker", "exec", "-it", "compose_bitcoind_1", "bitcoin-cli", "-getinfo"])
    elif arguments['lnd'] == True:
      if arguments['start'] == True:
        print("lnd start not implemented yet")
      elif arguments['stop'] == True:
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "stop"])
      elif arguments['logs'] == True:
        chdir("/home/lncm/compose")
        call(["docker-compose", "logs", "-f", "compose_lnd_1"])
        if arguments['--tail'] == True:
          call(["tail", "-f", "/media/volatile/volatile/lnd/logs/bitcoin/mainnet/lnd.log"])
      elif arguments['info'] == True:
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "getinfo"])
      elif arguments['create'] == True:
        # TODO: Inline create wallet script
        # This will either import an existing seed (or our own generated one), or use LND to create one. 
        # It will also create a password either randomly or use an existing password provided)
        call(["/usr/local/sbin/lncm-createwallet.py"])
      elif arguments['unlock'] == True:
        # manually unlock lnd wallet
        call(["docker", "exec", "-it", "compose_lnd_1", "lncli", "unlock"])