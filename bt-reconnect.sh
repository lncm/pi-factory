#!/bin/sh

/sbin/ifconfig bnep0 > /dev/null 2>&1
if [ "$?" -ne "0" ]; then
  /home/pi/bin/bt-stuff.py $(cat ~/bin/bluetooth-MACs | tr '\n' ' ') 2>/dev/null
fi
