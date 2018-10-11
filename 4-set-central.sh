#!/bin/bash -xe

sudo systemctl restart iptables
sudo iptables -I INPUT 9 -p tcp -m multiport --dports 12345 -m state --state NEW -m comment --comment "for DMA" -j ACCEPT

docker inspect grafana | grep running || \
 sudo docker run -d --name=grafana -p 3000:3000 grafana/grafana


echo "=====$0 end====="

