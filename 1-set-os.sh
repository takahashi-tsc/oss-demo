#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/overcloudrc.v3

# OpenStack Check and operate
function osc () {
  openstack $1 show ${!#} || \
  openstack $*
}

ls CentOS-7-x86_64-GenericCloud.qcow2 || \
 curl -O http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

osc image create --disk-format qcow2 --file CentOS-7-x86_64-GenericCloud.qcow2 centos-image

osc flavor create --ram 1024 --vcpus 1 m1.test

osc network create internal
osc subnet create --subnet-range 10.1.1.0/24 --network internal --dns-nameserver 192.168.122.1 internal-subnet

osc router create router1
openstack router set router1 --external-gateway external
openstack router add subnet router1 internal-subnet

osc keypair create --public-key ~/.ssh/id_rsa.pub test-keypair

echo "$0 end"
