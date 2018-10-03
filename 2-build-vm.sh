#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/overcloudrc.v3

openstack server list -c ID -f value | xargs openstack server delete
openstack floating ip list -c ID -f value | xargs openstack floating ip delete

openstack server create --image centos-image --flavor m1.test --key-name test-keypair --network internal --min 4 --max 4 testvm

while openstack server list | grep BUILD; do :; done

for p in $(openstack port list -c ID -f value --device-owner compute:nova)
do
  openstack floating ip create --port $p external
done


echo "$0 end"
