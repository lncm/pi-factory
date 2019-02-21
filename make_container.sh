#!/bin/sh

# Creates containers for docker from a running system with relevant docker images

get_id() {
  docker ps -aqf "name=${1}"
}

export iotwifi_ID=`get_id iotwifi`
export nginx_ID=`get_id nginx`

save_container() {
  docker save -o ${1}.tar.gz ${2}
}

if [ ! -d lncm-workdir ]; then
  mkdir lncm-workdir
fi

cd lncm-workdir

save_container iotwifi cjimti/iotwifi
save_container nginx nginx

if [ ! -d output ]; then
  mkdir output
fi

tar cvzf output/iotwifi.tar.gz iotwifi.tar.gz
tar cvzf output/nginx.tar.gz nginx.tar.gz