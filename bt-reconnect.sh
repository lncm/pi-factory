#!/bin/sh

/sbin/ifconfig bnep0 > /dev/null 2>&1
if [ "$?" -ne "0" ]; then
  cat ~/bin/bluetooth-MACs | while read line ; do
     /home/pi/fgtk/bt-pan client -r ${line} 2>/dev/null

     if [ "$?" -eq "0" ]; then
       echo "connected to ${line}"
       exit 0
     fi
  done
fi
