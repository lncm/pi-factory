#!/bin/sh

# Creates containers for docker from a running system with relevant docker images

get_id() {
  docker ps -aqf "name=${1}"
}

cmd_exists() {
  $(command -v ${1} 2>&1 1>/dev/null;)
  echo $?
}

if  [ ! "$(cmd_exists docker)" -eq "0" ]; then
  echo "Docker not found, aborting"
  exit 1
fi

iotwifi_ID=$(get_id iotwifi)
nginx_ID=$(get_id nginx)

export iotwifi_ID
export nginx_ID

save_container() {
  docker save -o "${1}".tar.gz "${2}"
}

if [ ! -d lncm-workdir ]; then
  mkdir lncm-workdir
fi

cd lncm-workdir || exit

if [ ! -d output ]; then
  mkdir output
fi

save_container output/iotwifi cjimti/iotwifi
save_container output/nginx nginx

cd output || exit

tar cvzf ../iotwifi.tar.gz iotwifi.tar.gz
tar cvzf ../nginx.tar.gz nginx.tar.gz