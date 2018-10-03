#!/bin/bash -x

unset OS_USERNAME OS_PASSWORD
source ~/overcloudrc.v3


openstack server list -c ID -f value | xargs openstack server delete
openstack floating ip list -c ID -f value | xargs openstack floating ip delete

openstack keypair delete test-keypair

openstack router remove subnet router1 internal-subnet
#openstack router set router1 --external-gateway external
openstack router delete router1

openstack subnet delete internal-subnet
openstack network delete internal

openstack flavor delete m1.test

openstack image delete centos-image
