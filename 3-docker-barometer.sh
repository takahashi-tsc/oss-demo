#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/stackrc

function getaddr (){
  openstack server show -c addresses -f value $1 | sed -e "s/ctlplane=/heat-admin@/"
}

COMPURI=$(getaddr overcloud-novacompute-0)

scp -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null \
 compute-tools/run_container.sh ${COMPURI}:

ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null ${COMPURI} \
 ./run_container.sh


echo "=====$0 end====="
