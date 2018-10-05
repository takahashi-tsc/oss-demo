#!/bin/bash -xe

CONFDIR=~/confdir
mkdir -p ${CONFDIR}

sudo docker rm -f barometer-collectd barometer-redis server infofetch || true

sudo docker pull opnfv/barometer-collectd

mkdir -p ${CONFDIR}/collectd_configs
sudo docker run -tid --net=host --name barometer-collectd \
 -v ${CONFDIR}/collectd_configs:/opt/collectd/etc/collectd.conf.d \
 -v /var/run:/var/run -v /tmp:/tmp --privileged opnfv/barometer-collectd /run_collectd.sh


cd ~
ls barometer || git clone https://gerrit.opnfv.org/gerrit/barometer
cd barometer/docker/barometer-dma
sudo docker build -t opnfv/barometer-dma --build-arg http_proxy=`echo $http_proxy` \
  --build-arg https_proxy=`echo $https_proxy` -f Dockerfile .


sudo docker run -tid -p 6379:6379 --name barometer-redis redis

mkdir -p ${CONFDIR}/dma-conf
cp ../../src/dma/examples/config.toml ${CONFDIR}/dma-conf/

if sudo ls /root/.ssh/id_rsa.pub; then
  echo "ssh-key already exists."
else
  sudo ssh-keygen -t rsa -N ""
  sudo cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys_org
  cat /root/.ssh/authorized_keys_org /root/.ssh/id_rsa.pub \
    > /root/.ssh/authorized_keys
fi

sudo docker run -tid --net=host --name server \
  -v ${CONFDIR}/dma-conf/:/etc/barometer-dma \
  -v /root/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ${CONFDIR}/collectd_configs:/etc/collectd/collectd.conf.d \
  opnfv/barometer-dma /server

sudo docker run -tid --net=host --name infofetch \
  -v ${CONFDIR}/dma-conf:/etc/barometer-dma \
  -v /var/run/libvirt:/var/run/libvirt \
  opnfv/barometer-dma /infofetch

sudo docker cp infofetch:/threshold ./
sudo rm -f /usr/local/bin/threshold
sudo ln -s ${PWD}/threshold /usr/local/bin/

echo "=====$0 end====="
