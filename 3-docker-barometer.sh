#!/bin/bash -xe

unset OS_USERNAME OS_PASSWORD
source ~/stackrc

function getaddr (){
  openstack server show -c addresses -f value $1 | sed -e "s/ctlplane=/heat-admin@/"
}

ssh -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null $(getaddr overcloud-novacompute-0) \
 sudo systemctl restart docker && \
 systemctl status docker 


echo "=====$0 end"=====
