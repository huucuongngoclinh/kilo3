#!/bin/bash -ex
#
source config.cfg

cd /etc/swift

swift-ring-builder account.builder create 10 3 1

swift-ring-builder account.builder add r1z1-$SWIFT_MGNT_IP:6002/sdb1 100
swift-ring-builder account.builder add r1z2-$SWIFT_MGNT_IP:6002/sdc1 100
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance

swift-ring-builder container.builder create 10 3 1
swift-ring-builder container.builder add r1z1-$SWIFT_MGNT_IP:6001/sdb1 100
swift-ring-builder container.builder add r1z2-$SWIFT_MGNT_IP:6001/sdc1 100
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance

swift-ring-builder object.builder create 10 3 1
swift-ring-builder object.builder add r1z1-$SWIFT_MGNT_IP:6000/sdb1 100
swift-ring-builder object.builder add r1z2-$SWIFT_MGNT_IP:6000/sdc1 100
swift-ring-builder object.builder
swift-ring-builder object.builder rebalance

curl -o /etc/swift/swift.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/kilo

sed -i 's/changeme/ \
openstack123/g' /etc/ntp.conf

echo "YOU NEDD COPY SOME FILES: swift.conf account.ring.gz, container.ring.gz, and object.ring.gz"

chown -R swift:swift /etc/swift

service memcached restart
service swift-proxy restart