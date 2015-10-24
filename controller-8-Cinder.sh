#!/bin/bash -ex
#

apt-get install -y cinder-api cinder-scheduler python-cinderclient

filecinder=/etc/cinder/cinder.conf
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rpc_backend = rabbit
my_ip = $CON_MGNT_IP

rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes

[database]
connection = mysql://cinder:$CINDER_DBPASS@$CON_MGNT_IP/cinder

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = $CINDER_PASS

[oslo_concurrency]
lock_path = /var/lock/cinder
EOF

chown cinder:cinder $filecinder

sleep 3
cinder-manage db sync

sleep 5
service cinder-api restart
service cinder-scheduler restart

rm -f /var/lib/cinder/cinder.sqlite

echo "Finish"