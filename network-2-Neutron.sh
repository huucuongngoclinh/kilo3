#!/bin/bash -ex
#

source config.cfg

iphost=/etc/hosts
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost
$CON_MGNT_IP    controller
$COM_MGNT_IP  	compute
$NET_MGNT_IP    network
$BLOCK_MGNT_IP  block
$SWIFT_MGNT_IP  swift
EOF

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p 

apt-get -y install neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent

netneutron=/etc/neutron/neutron.conf
rm $netneutron
touch $netneutron
cat << EOF >> $netneutron
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
verbose = True

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
[matchmaker_redis]
[matchmaker_ring]
[quotas]
[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = $NEUTRON_PASS

[database]

[nova]
[oslo_concurrency]
lock_path = \$state_path/lock
[oslo_policy]
[oslo_messaging_amqp]
[oslo_messaging_qpid]

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS
EOF

netl3agent=/etc/neutron/l3_agent.ini
rm $netl3agent
touch $netl3agent
cat << EOF >> $netl3agent
[DEFAULT]
verbose = True
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
external_network_bridge =
router_delete_namespaces = True
EOF
#

netdhcp=/etc/neutron/dhcp_agent.ini
rm $netdhcp
touch $netdhcp
cat << EOF >> $netdhcp
[DEFAULT]
verbose = True
dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf

interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
dhcp_delete_namespaces = True
EOF
#

echo "dhcp-option-force=26,1454" > /etc/neutron/dnsmasq-neutron.conf
killall dnsmasq

netmetadata=/etc/neutron/metadata_agent.ini
rm $netmetadata
touch $netmetadata
cat << EOF >> $netmetadata
[DEFAULT]
verbose = True

auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_region = regionOne
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = $NEUTRON_PASS

nova_metadata_ip = $CON_MGNT_IP

metadata_proxy_shared_secret = $METADATA_SECRET
EOF
#


netml2=/etc/neutron/plugins/ml2/ml2_conf.ini
rm $netml2
touch $netml2
cat << EOF >> $netml2
[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]
flat_networks = external

[ml2_type_vlan]

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]
[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovs]
local_ip = $NET_DATA_VM_IP
enable_tunneling = True
bridge_mappings = external:br-ex
 
[agent]

tunnel_types = gre

EOF

service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

# Starting up with OS
sed -i "s/exit 0/# exit 0/g" /etc/rc.local
echo "service openvswitch-switch restart" >> /etc/rc.local
echo "service neutron-plugin-openvswitch-agent restart" >> /etc/rc.local
echo "service neutron-l3-agent restart" >> /etc/rc.local
echo "service neutron-dhcp-agent restart" >> /etc/rc.local
echo "service neutron-metadata-agent restart" >> /etc/rc.local
echo "service neutron-lbaas-agent restart" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local


echo "export OS_USERNAME=admin" > admin-openrc.sh
echo "export OS_PASSWORD=$ADMIN_PASS" >> admin-openrc.sh
echo "export OS_TENANT_NAME=admin" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://$CON_MGNT_IP:35357/v2.0" >> admin-openrc.sh

sleep 1 
echo "Finish"


