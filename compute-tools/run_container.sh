#!/bin/bash -xe

# Args: File path
#  $1: setting
#  $2: collectd.service

source $1

if sudo grep DMA /usr/lib/systemd/system/collectd.service; then
  echo "collectd.service is already edited."
else
  sudo cp /usr/lib/systemd/system/collectd.service /usr/lib/systemd/system/collectd.service_org
  sudo cp -f $2 /usr/lib/systemd/system/collectd.service
  sudo systemctl daemon-reload
fi

CONFDIR=~/confdir
BINDIR=~/bindir
mkdir -p ${CONFDIR} ${BINDIR}


sudo systemctl restart docker

sudo docker rm -f barometer-collectd barometer-redis server infofetch || true
pkill -f grafana-redis-proxy || true


# Start redis
sudo docker run -tid -p 6379:6379 --name barometer-redis redis


# Start collectd

sudo docker pull opnfv/barometer-collectd

mkdir -p ${CONFDIR}/collectd_configs
sudo docker run -tid --net=host --name barometer-collectd \
 -v ${CONFDIR}/dma-conf:/etc/barometer-dma \
 -v ${BINDIR}:/home/collectd_exec/bin \
 -v ${CONFDIR}/collectd_configs:/opt/collectd/etc/collectd.conf.d \
 -v /var/run:/var/run -v /tmp:/tmp --privileged opnfv/barometer-collectd /run_collectd.sh

sudo docker stop barometer-collectd
sudo systemctl restart collectd


# Start DMA

cd ~
ls barometer || git clone https://gerrit.opnfv.org/gerrit/barometer
cd barometer/docker/barometer-dma
sudo docker build -t opnfv/barometer-dma --build-arg http_proxy=`echo $http_proxy` \
  --build-arg https_proxy=`echo $https_proxy` -f Dockerfile .

mkdir -p ${CONFDIR}/dma-conf
sudo cp -f ../../src/dma/examples/config.toml ${CONFDIR}/dma-conf/

sudo sed -i "s/^min.*$/min = 100000000/" ${CONFDIR}/dma-conf/config.toml
sudo sed -i "s/^amqp_password.*$/amqp_password = \"${MQ_PASS}\"/" ${CONFDIR}/dma-conf/config.toml
sudo sed -i "s/^os_password.*$/os_password = \"${OS_PASS}\"/" ${CONFDIR}/dma-conf/config.toml

if sudo ls /root/.ssh/id_rsa.pub; then
  echo "ssh-key already exists."
else
  sudo ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ""
  sudo cp -p /root/.ssh/authorized_keys /root/.ssh/authorized_keys_org
  sudo cat /root/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
fi

sudo docker run -tid --net=host --name server \
  -v ${CONFDIR}/dma-conf:/etc/barometer-dma \
  -v /root/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ${CONFDIR}/collectd_configs:/etc/collectd/collectd.conf.d \
  opnfv/barometer-dma /server

sudo docker run -tid --net=host --name infofetch \
  -v ${CONFDIR}/dma-conf:/etc/barometer-dma \
  -v /var/run/libvirt:/var/run/libvirt \
  opnfv/barometer-dma /infofetch

sudo docker cp infofetch:/threshold ./
sudo mv -f threshold ${BINDIR}/


# Import grafana-redis-proxy
sudo systemctl restart iptables
sudo iptables -I INPUT 5 -p tcp -m multiport --dports 8080 -m state --state NEW -m comment --comment "grafana-redis" -j ACCEPT

cd ~
sudo yum -y install golang
go get github.com/s1061123/grafana-redis-proxy
nohup ./go/bin/grafana-redis-proxy > grafana-redis-proxy.log 2> grafana-redis-proxy-err.log  < /dev/null &
sleep 1


echo "=====$0 end====="
