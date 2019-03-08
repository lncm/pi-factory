#!/bin/sh

# This script is a helper script that rewrites the host IP to the new IP Address (used for TOR only nodes).
# if the node LAN IP changes (or box is plugged into a new LAN), lnd is unable to obviously connect to the new TOR IP address.
# Basically this is an edge case right now as the merchant box should always have the same LAN IP.

# Copyright © 2018-2019 LNCM Contributors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

IP=$(ip route get 1 | awk '{print $NF;exit}')

# Look for existance of .ipaddress.txt
if [ ! -f /home/lncm/.ipaddress.txt ]; then
  # If doesn't exist set it up
  echo "$IP" > /home/lncm/.ipaddress.txt
  cp /media/important/important/lnd/lnd.conf /media/important/important/lnd.conf.old
  # replace TORIPADDRESS in config with the IP
  sed -i "s/TORIPADDRESS/$IP/g; " /media/important/important/lnd/lnd.conf
else
  OLDIP=$(cat /home/lncm/.ipaddress.txt)
  if [ ! "$OLDIP" = "$IP" ]; then
    cp /media/important/important/lnd/lnd.conf /media/important/important/lnd.conf.old
    sed -i "s/$OLDIP/$IP/g; " /media/important/important/lnd/lnd.conf
    echo "$IP" > /home/lncm/.ipaddress.txt
  fi
fi
