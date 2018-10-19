#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/overcloudrc.v3

# OpenStack Check and operate
function osc () {
  openstack $1 show ${!#} || \
  openstack $*
}


SECG_ID=$(openstack security group list -c ID -f value --project admin)
openstack security group rule list -c ID -f value ${SECG_ID} | \
 xargs openstack security group rule delete || true
openstack security group rule create --egress --protocol icmp ${SECG_ID}
openstack security group rule create --egress --protocol tcp ${SECG_ID}
openstack security group rule create --ingress --protocol icmp ${SECG_ID}
openstack security group rule create --ingress --protocol tcp --dst-port 22 ${SECG_ID}


ls CentOS-7-x86_64-GenericCloud.qcow2 || \
 curl -O http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

osc image create --disk-format qcow2 --file CentOS-7-x86_64-GenericCloud.qcow2 centos-image

osc flavor create --ram 1024 --vcpus 1 m1.test

osc network create internal
osc subnet create --subnet-range 10.1.1.0/24 --network internal \
 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 internal-subnet

osc router create router1
openstack router set router1 --external-gateway external || true
openstack router add subnet router1 internal-subnet || true

osc keypair create --public-key ~/.ssh/id_rsa.pub test-keypair

echo "=====$0 end====="
