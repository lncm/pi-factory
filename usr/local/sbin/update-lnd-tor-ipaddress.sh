# This script is a helper script that rewrites the host IP to the new IP Address (used for TOR only nodes).
# if the node LAN IP changes (or box is plugged into a new LAN), lnd is unable to obviously connect to the new TOR IP address.
# Basically this is an edge case right now as the merchant box should always have the same LAN IP.

IP=`ip route get 1 | awk '{print $NF;exit}'`

# Look for existance of .ipaddress.txt
if [ ! -f /home/lncm/.ipaddress.txt ]; then
  # If doesn't exist set it up
  echo $IP > /home/lncm/.ipaddress.txt
  cp /media/important/lnd/lnd.conf /media/important/lnd.conf.old
  # replace TORIPADDRESS in config with the IP
  sed "s/TORIPADDRESS/$IP/g; " /media/important/lnd/lnd.conf
else
  OLDIP=$(cat /home/lncm/.ipaddress.txt)
  if [ ! $OLDIP == $IP ]; then
    cp /media/important/lnd/lnd.conf /media/important/lnd.conf.old
    sed "s/$OLDIP/$IP/g; " /media/important/lnd/lnd.conf
    echo $IP > /home/lncm/.ipaddress.txt
  fi
fi
