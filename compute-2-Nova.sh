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

apt-get -y update
apt-get -y install nova-compute sysfsutils
apt-get install libguestfs-tools -y

echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

sleep 5

filenova=/etc/nova/nova.conf
test -f $filenova.orig || cp $filenova $filenova.orig
cat << EOF > $filenova
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

#fix loi instances fails to allocate the network
vif_plugging_is_fatal = False
vif_plugging_timeout = 0

my_ip = $COM_MGNT_IP
vnc_enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $COM_MGNT_IP
novncproxy_base_url = http://$CON_EXT_IP:6080/vnc_auto.html

allow_resize_to_same_host=True
scheduler_default_filters=AllHostsFilter
libvirt_inject_password = True
enable_instance_password = True
libvirt_inject_key = true
libvirt_inject_partition = -1

network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver

dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
# lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
# verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[oslo_concurrency]
lock_path = /var/lock/nova

[neutron]
url = http://$CON_MGNT_IP:9696
auth_strategy = keystone
admin_auth_url = http://$CON_MGNT_IP:35357/v2.0
admin_tenant_name = service
admin_username = neutron
admin_password = $NEUTRON_PASS

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $NOVA_PASS

[glance]
host = $CON_MGNT_IP

EOF

rm /var/lib/nova/nova.sqlite

echo 'kvm_intel' >> /etc/modules

service nova-compute restart
service nova-compute restart

apt-get -y install neutron-common neutron-plugin-ml2 neutron-plugin-openvswitch-agent


comfileneutron=/etc/neutron/neutron.conf
rm $comfileneutron 
cat << EOF > $comfileneutron
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
verbose = True

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
# connection = sqlite:////var/lib/neutron/neutron.sqlite
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

comfileml2=/etc/neutron/plugins/ml2/ml2_conf.ini
rm $comfileml2
touch $comfileml2
cat << EOF > $comfileml2
[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]
[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovs]
local_ip = $COM_DATA_VM_IP
enable_tunneling = True

[agent]
tunnel_types = gre

EOF

service openvswitch-switch restart

echo 'kvm_intel' >> /etc/modules

service nova-compute restart
service nova-compute restart

service neutron-plugin-openvswitch-agent restart
service neutron-plugin-openvswitch-agent restart

echo "########## Creating Environment script file ##########"
sleep 5
echo "export OS_USERNAME=admin" > admin-openrc.sh
echo "export OS_PASSWORD=$ADMIN_PASS" >> admin-openrc.sh
echo "export OS_TENANT_NAME=admin" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://$CON_MGNT_IP:35357/v2.0" >> admin-openrc.sh

echo "Finish"