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
   -r compute-tools setting ${COMP_URI}:

  ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null ${COMP_URI} \
   ./compute-tools/run_container.sh ./setting ./compute-tools/collectd.service ./compute-tools/influxdb.conf
done

echo "=====$0 end====="
