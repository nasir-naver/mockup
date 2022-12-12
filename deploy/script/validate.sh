#!/bin/bash

current_push_port=$(cat /etc/nginx/conf.d/outsidebank*.conf | grep -o '127.0.0.1:[0-9]*' | sed 's/127\.0\.0\.1://g')
let "current_pull_port=$current_push_port+1"

# if [ ! $(fuser $current_push_port/tcp) ]; then
#   echo "error: push server is not running"
#   exit 1
# elif [ ! $(fuser $current_pull_port/tcp) ]; then
#   echo "error: pull server is not running"
#   exit 1
# else
#   echo "ok"
# fi
