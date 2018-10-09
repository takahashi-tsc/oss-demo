#!/bin/bash -xe

source $1

if sudo grep DMA /usr/lib/systemd/system/collectd.service; then
  echo "collectd.service is already edited."
else
  sudo mv /usr/lib/systemd/system/collectd.service /usr/lib/systemd/system/collectd.service_org
  sudo cp $2 /usr/lib/systemd/system/collectd.service
  sudo systemctl daemon-reload
fi

CONFDIR=~/confdir
BINDIR=~/bindir
mkdir -p ${CONFDIR} ${BINDIR}


sudo systemctl restart docker

sudo docker rm -f barometer-collectd barometer-redis server infofetch || true

sudo docker run -tid -p 6379:6379 --name barometer-redis redis


sudo docker pull opnfv/barometer-collectd

mkdir -p ${CONFDIR}/collectd_configs
sudo docker run -tid --net=host --name barometer-collectd \
 -v ${CONFDIR}/dma-conf:/etc/barometer-dma \
 -v ${BINDIR}:/home/collectd_exec/bin \
 -v ${CONFDIR}/collectd_configs:/opt/collectd/etc/collectd.conf.d \
 -v /var/run:/var/run -v /tmp:/tmp --privileged opnfv/barometer-collectd /run_collectd.sh

sudo docker stop barometer-collectd
sudo systemctl restart collectd


cd ~
ls barometer || git clone https://gerrit.opnfv.org/gerrit/barometer
cd barometer/docker/barometer-dma
sudo docker build -t opnfv/barometer-dma --build-arg http_proxy=`echo $http_proxy` \
  --build-arg https_proxy=`echo $https_proxy` -f Dockerfile .


mkdir -p ${CONFDIR}/dma-conf
cp ../../src/dma/examples/config.toml ${CONFDIR}/dma-conf/

sed -i "s/^amqp_password.*$/amqp_password = \"${MQ_PASS}\"/" ${CONFDIR}/dma-conf/config.toml
sed -i "s/^os_password.*$/os_password = \"${OS_PASS}\"/" ${CONFDIR}/dma-conf/config.toml

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
sudo mv threshold ${BINDIR}/

echo "=====$0 end====="
