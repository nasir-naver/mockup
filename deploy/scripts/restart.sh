#!/bin/bash

PATH=$PATH:/usr/sbin
export PATH

deploy_home=/home/lendit/deploy/outsidebank
current_push_port=$(cat /etc/nginx/conf.d/outsidebank*.conf | grep -o '127.0.0.1:[0-9]*' | sed 's/127\.0\.0\.1://g')

if [ "$current_push_port" = "30010" ]; then
  target_ver=2
else
  target_ver=1
fi

target_home=/home/outsidebank$target_ver
target_src_dir=$target_home/src
let "target_push_port=30000+10*$target_ver"
let "target_pull_port=$target_push_port+1"
let "current_pull_port=(30011+30021)-$target_pull_port"

echo 'kill payment monitor...'
kill $(ps -ef | grep python | grep payment_monitor | awk {'print $2'})
echo 'wait terminating payment monitor...'
while [ ! -z $(ps -ef | grep python | grep payment_monitor | awk {'print $2'}) ]; do
  sleep 1
done

echo 'kill push and pull server...'
if [ $(fuser $target_push_port/tcp) ]; then
  echo "kill push server - $target_push_port"
  fuser -n tcp -k $target_push_port 2>&1 > /dev/null || exit 1
fi
if [ $(fuser $target_pull_port/tcp) ]; then
  echo "kill pull server - $target_pull_port"
  fuser -n tcp -k $target_pull_port 2>&1 > /dev/null || exit 1
fi

if [ -d "$target_src_dir" ]; then
  rm -r $target_src_dir
fi

cp -r $deploy_home $target_src_dir

cd $target_src_dir
source ../venv/bin/activate
pip install -U -r requirements.txt

OUTSIDEBANK_ENV=dev nohup python -m outsidebank.push $target_push_port > ../logs/push.log 2>&1 &
OUTSIDEBANK_ENV=dev nohup python -m outsidebank.pull $target_pull_port > ../logs/pull.log 2>&1 &
OUTSIDEBANK_ENV=dev nohup python -m outsidebank.payment_monitor > ../logs/payment_monitor.log 2>&1 &

echo 'wait and check ports'
sleep 3
if [ ! $(fuser $target_push_port/tcp) ] || [ ! $(fuser $target_pull_port/tcp) ]; then
  exit 1
fi

echo 'write nginx config'
sudo rm -f /etc/nginx/conf.d/outsidebank*.conf
sudo cp "$target_src_dir/outsidebank$target_ver.conf" /etc/nginx/conf.d/ || exit 1

echo 'reload nginx config'
sudo service nginx reload || exit 1

echo 'change iptables'
sudo iptables -t nat -A PREROUTING -i bond0 -p tcp --dport 30001 -j REDIRECT --to-ports $target_pull_port || exit 1
sudo iptables -t nat -D PREROUTING -i bond0 -p tcp --dport 30001 -j REDIRECT --to-ports $current_pull_port

rm -rf $deploy_home
echo 'done'
