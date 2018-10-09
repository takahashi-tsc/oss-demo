#!/bin/bash -xe

sudo systemctl restart iptables
sudo iptables -I INPUT 9 -p tcp -m multiport --dports 12345 -m state --state NEW -m comment --comment "for DMA" -j ACCEPT
