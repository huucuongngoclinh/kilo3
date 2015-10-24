#!/bin/bash -ex
#
source config.cfg

apt-get -y install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main" \
    | sudo tee /etc/apt/sources.list.d/cloud-archive.list

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y

apt-get install -y openvswitch-switch 

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent neutron-plugin-openvswitch neutron-common
  
apt-get install ntp -y
apt-get install python-mysqldb -y

cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf
#
sed -i 's/server 0.ubuntu.pool.ntp.org/ \
#server 0.ubuntu.pool.ntp.org/g' /etc/ntp.conf

sed -i 's/server 1.ubuntu.pool.ntp.org/ \
#server 1.ubuntu.pool.ntp.org/g' /etc/ntp.conf

sed -i 's/server 2.ubuntu.pool.ntp.org/ \
#server 2.ubuntu.pool.ntp.org/g' /etc/ntp.conf

sed -i 's/server 3.ubuntu.pool.ntp.org/ \
#server 3.ubuntu.pool.ntp.org/g' /etc/ntp.conf

sed -i "s/server ntp.ubuntu.com/server $CON_MGNT_IP iburst/g" /etc/ntp.conf

ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth1

ifaces=/etc/network/interfaces
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto br-ex
iface br-ex inet static
address $NET_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet manual
   up ifconfig \$IFACE 0.0.0.0 up
   up ip link set \$IFACE promisc on
   down ip link set \$IFACE promisc off
   down ifconfig \$IFACE down

auto eth0
iface eth0 inet static
address $NET_MGNT_IP
netmask $NETMASK_ADD

auto eth2
iface eth2 inet static
address $NET_DATA_VM_IP
netmask $NETMASK_ADD
EOF

echo "network" > /etc/hostname
hostname -F /etc/hostname
init 6

