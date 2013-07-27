# admin

/etc/init.d/openstack-nova-api stop
/etc/init.d/openstack-nova-cert stop
/etc/init.d/openstack-nova-compute stop
/etc/init.d/openstack-nova-conductor stop
/etc/init.d/openstack-nova-network stop
/etc/init.d/openstack-nova-scheduler stop

iptables -t nat -X
iptables -t nat -F
iptables -X
iptables -F


su - postgres -c "echo 'drop database nova' | psql"
su - postgres -c "echo 'create database nova' | psql"
nova-manage db sync

export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://192.168.122.21:35357/v2.0"
TENANT_ID=`keystone tenant-list | grep admin |awk '{print $2}'`
unset SERVICE_TOKEN
unset SERVICE_ENDPOINT

nova-manage network create  --bridge=br100 --bridge_interface=eth0 \
 --fixed_range_v4=10.0.0.0/24 --num_network=1 --network_size=128 --label=priv1 --gateway=10.0.0.1 --fixed_cidr=10.0.0.0/24 --project=${TENANT_ID}
#nova-manage network create --vlan=101 --bridge=br101 --bridge_interface=eth0 \
# --fixed_range_v4=10.0.1.0/24 --num_network=1 --network_size=32 --label=priv2 --gateway=10.0.1.1 --fixed_cidr=10.0.1.0/24 --project=${TENANT_ID}

# demo
#export SERVICE_TOKEN=ADMIN
#export SERVICE_ENDPOINT="http://192.168.122.21:35357/v2.0"
#TENANT_ID=`keystone tenant-list | grep demo |awk '{print $2}'`
#unset SERVICE_TOKEN
#unset SERVICE_ENDPOINT
#nova-manage network create  --bridge=br102 --bridge_interface=eth0 \
# --fixed_range_v4=10.0.2.0/24 --num_network=1 --network_size=32 --label=priv1 --gateway=10.0.2.1 --fixed_cidr=10.0.2.0/24 --project=${TENANT_ID}
##nova-manage network create --vlan=103 --bridge=br103 --bridge_interface=eth0 \
## --fixed_range_v4=10.0.3.0/24 --num_network=1 --network_size=32 --label=priv2 --gateway=10.0.3.1 --fixed_cidr=10.0.3.0/24 --project=${TENANT_ID}

#nova-manage network create --label=public --fixed_range_v4=10.0.0.0/8 --num_networks=4 --network_size=32 --vlan=128 --gateway=10.0.0.1 --fixed_cidr=10.0.0.0/16 --bridge=br100 --bridge_interface=eth0

nova-manage network list
nova-manage floating create --ip_range=192.168.122.128/28 --interface=eth0 --pool=pool1
nova-manage floating list

#/etc/init.d/nova-api start
#/etc/init.d/nova-network start
#/etc/init.d/nova-scheduler start
#sleep 5
#euca-authorize -P tcp -p 22 default
#euca-authorize -P icmp -t -1:-1 default

source /root/stackrc

nova secgroup-add-rule default tcp 22 22 192.168.0.0/16
nova secgroup-add-rule default icmp -1 -1 192.168.0.0/16

