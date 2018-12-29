#!/bin/sh

if [ "$1" = "" ]; then
  echo -e "Mana: node management\n"
  echo "Must pass an option:"
  echo "info, unlock, create, stop, start, temp"
fi

if [ "$1" = "info" ]; then
  # bitcoind and lnd information
  echo "bitcoind info:"
  docker exec -it compose_btcbox_1 bitcoin-cli -getinfo
  echo "lnd info:"
  docker exec -it compose_lightningbox_1 lncli getinfo
fi

if [ "$1" = "unlock" ]; then
  # unlock lnd wallet
  docker exec -it compose_lightningbox_1 lncli unlock
fi

if [ "$1" = "create" ]; then
  # create lnd wallet
  docker exec -it compose_lightningbox_1 lncli create
fi

if [ "$1" = "start" ]; then
  service docker-compose start
fi

if [ "$1" = "stop" ]; then
  echo "Attempting clean shutdown of bitcoind and lnd nodes"
  docker exec -it compose_lightningbox_1 lncli stop
  docker exec -it compose_btcbox_1 bitcoin-cli stop
fi

if [ "$1" = "temp" ]; then
  # CPU temperature
  cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
  echo "CPU: $((cpu/1000))C"
fi
