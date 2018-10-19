#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/overcloudrc.v3

openstack server list -c ID -f value | xargs openstack server delete || true
openstack floating ip list -c ID -f value | xargs openstack floating ip delete || true

openstack server create --image centos-image --flavor m1.test --key-name test-keypair \
 --user-data vm-tools/setup.sh --network internal --min 4 --max 4 testvm

while openstack server list | grep BUILD; do echo "Wait active..." ; done

for p in $(openstack port list -c ID -f value --device-owner compute:nova)
do
  openstack floating ip create --port $p external
  IP=$(openstack floating ip list -c "Floating IP Address" -f value --port ${p})
  ssh-keygen -R ${IP}

  until ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null \
   centos@${IP} ls
  do
    echo Wait ssh...
    sleep 5
  done

  scp -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null \
   -r vm-tools centos@${IP}:
done


echo "=====$0 end====="
