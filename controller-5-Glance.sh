#!/bin/bash -ex
#
source config.cfg

apt-get -y install glance python-glanceclient

fileglanceapicontrol=/etc/glance/glance-api.conf
rm $fileglanceapicontrol
touch $fileglanceapicontrol
cat << EOF > $fileglanceapicontrol
[DEFAULT]
notification_driver = noop
verbose = True

bind_host = 0.0.0.0
bind_port = 9292
log_file = /var/log/glance/api.log
backlog = 4096
registry_host = 0.0.0.0
registry_port = 9191
registry_client_protocol = http
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = guest
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True
delayed_delete = False
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber
image_cache_dir = /var/lib/glance/image-cache/
[oslo_policy]

[database]
connection = mysql://glance:$GLANCE_DBPASS@$CON_MGNT_IP/glance
backend = sqlalchemy
[oslo_concurrency]

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000/v2.0
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = $GLANCE_PASS


[paste_deploy]
flavor = keystone

[store_type_location_strategy]
[profiler]
[task]
[taskflow_executor]

[glance_store]
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

default_store = file
filesystem_store_datadir = /var/lib/glance/images/

swift_store_auth_version = 2
swift_store_auth_address = 127.0.0.1:5000/v2.0/
swift_store_user = jdoe:jdoe
swift_store_key = a86850deb2742ec3cb41518e26aa2d89
swift_store_container = glance
swift_store_create_container_on_put = False
swift_store_large_object_size = 5120
swift_store_large_object_chunk_size = 200
s3_store_host = s3.amazonaws.com
s3_store_access_key = <20-char AWS access key>
s3_store_secret_key = <40-char AWS secret key>
s3_store_bucket = <lowercased 20-char aws access key>glance
s3_store_create_bucket_on_put = False
sheepdog_store_address = localhost
sheepdog_store_port = 7000
sheepdog_store_chunk_size = 64

EOF

fileglanceregcontrol=/etc/glance/glance-registry.conf
rm $fileglanceregcontrol
touch $fileglanceregcontrol
cat << EOF > $fileglanceregcontrol
[DEFAULT]
notification_driver = noop
verbose = True

bind_host = 0.0.0.0
bind_port = 9191
log_file = /var/log/glance/registry.log
backlog = 4096
api_limit_max = 1000
limit_param_default = 25
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = guest
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True
[oslo_policy]

[database]
connection = mysql://glance:$GLANCE_DBPASS@$CON_MGNT_IP/glance
backend = sqlalchemy

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000/v2.0
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = $GLANCE_PASS

[paste_deploy]
flavor = keystone

[profiler]
EOF

sleep 3

rm /var/lib/glance/glance.sqlite

chown glance:glance $fileglanceapicontrol
chown glance:glance $fileglanceregcontrol

sleep 7
glance-manage db_sync
sleep 7
service glance-registry restart
service glance-api restart
sleep 3
service glance-registry restart
service glance-api restart

#
sleep 3
mkdir -p images
cd images/

source /root/admin-openrc.sh
glance image-create --name "cirros-0.3.3-x86_64" --disk-format qcow2 --container-format bare --is-public True --progress < cirros-0.3.3-x86_64-disk.img
cd /root/

glance image-list
