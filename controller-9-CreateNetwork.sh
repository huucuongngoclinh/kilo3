#!/bin/bash -ex
#
echo "########## policy ##########"
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0

neutron net-create ext-net --router:external --provider:physical_network external --provider:network_type flat

neutron subnet-create ext-net 192.168.$ID.0/24 --name ext-subnet --allocation-pool start=192.168.$ID.101,end=192.168.$ID.200 --disable-dhcp --gateway 192.168.$ID.$GATEWAY_END

neutron net-create int-net
sleep 3
neutron subnet-create int-net --name int-subnet --dns-nameserver 8.8.8.8 172.16.10.0/24
sleep 3
neutron router-create router_1
sleep 3
neutron router-interface-add router_1 int-subnet
sleep 3
neutron router-gateway-set router_1 ext-net
sleep 3

ID_int_net=`neutron net-list | awk '/int*/ {print $2}'`
nova boot test --image cirros-0.3.3-x86_64 --flavor 1 --security-groups default --nic net-id=$ID_int_net
sleep 10
nova list
echo "Finished"
