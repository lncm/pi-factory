#!/bin/bash

exec > ~/setup.log 2>&1
set -x

function wrap_up() {
  sudo cp ~/setup.log /boot

  sleep 5
  sudo halt
}
trap 'wrap_up' TERM INT HUP

sudo touch /boot/blabla

wrap_up
