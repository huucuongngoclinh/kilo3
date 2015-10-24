#!/bin/bash -ex
#
source config.cfg

apt-get -y install swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached
curl -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/kilo

fileproxyserver=/etc/swift/proxy-server.conf
rm $fileproxyserver
cat << EOF > $fileproxyserver
[DEFAULT]
bind_port = 8080
swift_dir =/etc/swift
user =swift

[pipeline:main]
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo proxy-$

[app:proxy-server]
use = egg:swift#proxy
#allow_account_management = true
account_autocreate = true

[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3
user_test5_tester5 = testing5 service

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
auth_uri = http://$CON_MGNT_IP:5000/
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = swift
password = $SWIFT_PASS
delay_auth_decision = true
#signing_dir = /home/swift/keystone-signing

[filter:keystoneauth]
use = egg:swift#keystoneauth
#operator_roles = admin,_member_,Member,swiftoperator
operator_roles = admin,_member_
[filter:healthcheck]
use = egg:swift#healthcheck

[filter:cache]
use = egg:swift#memcache
memcache_servers = 127.0.0.1:11211
[filter:ratelimit]
use = egg:swift#ratelimit

[filter:domain_remap]
use = egg:swift#domain_remap

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cname_lookup]
use = egg:swift#cname_lookup

[filter:staticweb]
use = egg:swift#staticweb

[filter:tempurl]
use = egg:swift#tempurl

[filter:formpost]
use = egg:swift#formpost

[filter:name_check]
use = egg:swift#name_check

[filter:list-endpoints]
use = egg:swift#list_endpoints

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:bulk]
use = egg:swift#bulk
[filter:slo]
use = egg:swift#slo

[filter:dlo]
use = egg:swift#dlo

[filter:container-quotas]
use = egg:swift#container_quotas

[filter:account-quotas]
use = egg:swift#account_quotas

[filter:gatekeeper]
use = egg:swift#gatekeeper

[filter:container_sync]
use = egg:swift#container_sync

[filter:xprofile]
use = egg:swift#xprofile

EOF

