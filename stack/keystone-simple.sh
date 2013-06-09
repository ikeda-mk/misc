#!/bin/sh

# Tenant               User      Roles
# ------------------------------------------------------------------
# admin                admin     admin   (本手順書では未使用テナント/ユーザ)
# service              glance    admin
# service              nova      admin
#
# sys1                 sys1      admin
# sys1                 admin     admin


mysql -ustack -pstack -e 'DROP DATABASE IF EXISTS keystone;'
mysql -ustack -pstack -e 'CREATE DATABASE keystone CHARACTER SET utf8;'
#echo "drop database if exists keystone;" | mysql -ukeystone -pkeystone
#echo "create database keystone;" | mysql -ukeystone -pkeystone
keystone-manage db_sync

keystone --token=ADMIN --endpoint=http://127.0.0.1:35357/v2.0/ tenant-create --name=admin
keystone --token=ADMIN --endpoint=http://127.0.0.1:35357/v2.0/ tenant-create --name=service
keystone --token=ADMIN --endpoint=http://127.0.0.1:35357/v2.0/ tenant-create --name=sys1
keystone --token=ADMIN --endpoint=http://127.0.0.1:35357/v2.0/ tenant-list

keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-create --name=admin --pass="admin" --email=admin@example.com
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-create --name=glance --pass="glance" --email=glance@example.com
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-create --name=nova --pass="nova" --email=nova@example.com
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-create --name=sys1 --pass="sys1" --email=sys1@example.com
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list

keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ role-create --name=admin
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ role-list


ADMIN_ROLE=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ role-list | grep admin | awk '{ print $2 }'`
ADMIN_USER=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list | grep admin | awk '{ print $2 }'`
ADMIN_TENANT=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ tenant-list | grep admin | awk '{ print $2 }'`

SYS1_USER=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list | grep sys1 | awk '{ print $2 }'`
SYS1_TENANT=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ tenant-list | grep sys1 | awk '{ print $2 }'`

echo "$ADMIN_ROLE"
echo "$ADMIN_USER"
echo "$ADMIN_TENANT"

keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant_id $ADMIN_TENANT
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-role-add --user-id $SYS1_USER --role-id $ADMIN_ROLE --tenant_id $SYS1_TENANT
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant_id $SYS1_TENANT

SERVICE_TENANT=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ tenant-list | grep service | awk '{ print $2 }'`
NOVA_USER=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list | grep nova | awk '{ print $2 }'`
GLANCE_USER=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list | grep glance | awk '{ print $2 }'`
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-role-add --tenant_id $SERVICE_TENANT --user-id $NOVA_USER --role-id $ADMIN_ROLE
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    user-role-add --tenant_id $SERVICE_TENANT --user-id $GLANCE_USER --role-id $ADMIN_ROLE


## ec2-credentials-create

keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    ec2-credentials-create --user-id $ADMIN_USER --tenant-id $ADMIN_TENANT
keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    ec2-credentials-create --user-id $SYS1_USER --tenant-id $SYS1_TENANT


keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
    ec2-credentials-list --user-id $SYS1_USER 


users='admin sys1'

for u in $users;
do
    mkdir -p /root/creds/$u;

    uid=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ user-list | grep $u | awk '{ print $2 }'`
    ec2_creds=`keystone --token=ADMIN --endpoint http://127.0.0.1:35357/v2.0/ \
        ec2-credentials-list --user-id $uid | grep "$u" | awk '{ print $4,$6}'`
    access=`echo $ec2_creds | awk '{ print $1}'`
    secret=`echo $ec2_creds | awk '{ print $2}'`
    echo $access
    echo $secret


cat << EOS > /root/creds/$u/openrc
export OS_USERNAME=$u 
export OS_PASSWORD=$u
export OS_TENANT_NAME=$u
export OS_AUTH_URL=http://192.168.0.110:5000/v2.0
export EC2_ACCESS_KEY=$access
export EC2_SECRET_KEY=$secret
export EC2_URL=http://192.168.0.110:8773/services/Cloud
EOS

done
