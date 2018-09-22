#!/bin/sh

/sbin/ifconfig bnep0 > /dev/null 2>&1
if [ "$?" -ne "0" ]; then
  /home/pi/fgtk/bt-pan client -r 40:4E:36:A6:F8:18
fi
