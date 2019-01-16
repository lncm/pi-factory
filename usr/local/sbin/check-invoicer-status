#!/bin/sh

# financial-independence / dockerfiles
# Copyright (C) 2018 and onwards  LNCM Contributors

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ -z $BOXNAME ]; then
    BOXNAME='compose_invoicerbox_1'
fi

if command -v docker 2>&1 1>/dev/null; [ "$?" -ne "0" ]; then
    echo "Docker is not installed"
    exit 1
fi

if command -v jq 2>&1 1>/dev/null; [ "$?" -ne "0" ]; then
    echo "jq is not installed"
    exit 1
fi
if [ "$(id -u)" -ne "0" ]; then
    echo "This tool must be run as root"
    exit 1
fi

if [ $(docker ps -a | grep -c $BOXNAME) == 1 ]; then
    if [ $(docker inspect $BOXNAME | jq '.[0].State.Status' | sed 's/"//g; ') == "running" ]; then
        if [ $(docker inspect $BOXNAME | jq '.[0].State.Health.Status' | sed 's/"//g; ') == "healthy" ]; then
            echo "All good"
            exit 0
        else
            echo "Attempting to restart $BOXNAME"
            docker stop $BOXNAME
            docker start $BOXNAME
            exit 0
        fi
    fi
fi

