#!/bin/sh

# Creates containers for docker from a running system with relevant docker images

get_id() {
  docker ps -aqf "name=${1}"
}

save_container() {
  docker export -o ${1}.tar.gz ${2}
}

export iotwifi_ID=`get_id iotwifi`
export nginx_ID=`get_id nginx`

save_container iotwifi ${iotwifi_ID}
save_container nginx ${nginx_ID}