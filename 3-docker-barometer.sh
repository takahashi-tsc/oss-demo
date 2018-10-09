#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/stackrc

source setting

function getaddr (){
  openstack server show -c addresses -f value $1 | sed -e "s/ctlplane=/heat-admin@/"
}

for host_n in ${COMPUTES}
do
  COMP_URI=$(getaddr ${host_n})

  scp -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null \
   compute-tools/run_container.sh compute-tools/collectd.service setting ${COMP_URI}:

  ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null ${COMP_URI} \
   ./run_container.sh ./setting ./collectd.service
done

echo "=====$0 end====="
