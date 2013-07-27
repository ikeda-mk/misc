#!/bin/sh

/etc/init.d/openstack-keystone stop
sleep 1
su postgres -c "echo drop database keystone | psql"
su postgres -c "echo create database keystone | psql"
keystone-manage db_sync
/etc/init.d/openstack-keystone start
sleep 5

ADMIN_PASSWORD=admin
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$ADMIN_PASSWORD}
#export SERVICE_TOKEN=$SERVICE_TOKEN
#export SERVICE_ENDPOINT=$SERVICE_ENDPOINT
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0
SERVICE_TENANT_NAME=service
ENABLED_SERVICES=quantum

function get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
echo "keystone tenant-create --name=admin"
ADMIN_TENANT=$(get_id keystone tenant-create --name=admin)
echo "keystone tenant-create --name=$SERVICE_TENANT_NAME"
SERVICE_TENANT=$(get_id keystone tenant-create --name=$SERVICE_TENANT_NAME)
echo "keystone tenant-create --name=demo"
DEMO_TENANT=$(get_id keystone tenant-create --name=demo)


# Users

echo "keystone user-create --name=admin \\
                     --pass=admin \\
                     --email=admin@example.com"
ADMIN_USER=$(get_id keystone user-create --name=admin \
                                         --pass=admin \
                                         --email=admin@example.com)
echo "keystone user-create --name=demo --pass=demo --email=demo@example.com"
DEMO_USER=$(get_id keystone user-create --name=demo \
                                        --pass=demo \
                                        --email=demo@example.com)


# Roles
echo "keystone role-create --name=admin"
ADMIN_ROLE=$(get_id keystone role-create --name=admin)

echo "keystone role-create --name=KeystoneAdmin"
KEYSTONEADMIN_ROLE=$(get_id keystone role-create --name=KeystoneAdmin)

echo "keystone role-create --name=KeystoneServiceAdmin"
KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name=KeystoneServiceAdmin)

# ANOTHER_ROLE demonstrates that an arbitrary role may be created and used
# TODO(sleepsonthefloor): show how this can be used for rbac in the future!
echo "keystone role-create --name=anotherrole"
ANOTHER_ROLE=$(get_id keystone role-create --name=anotherrole)


# Add Roles to Users in Tenants
echo "keystone user-role-add \\
        --user-id $ADMIN_USER \\
        --role-id $ADMIN_ROLE \\
        --tenant-id $ADMIN_TENANT"
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
echo "keystone user-role-add \\
        --user-id $ADMIN_USER \\
        --role-id $ADMIN_ROLE \\
        --tenant-id $DEMO_TENANT"
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $DEMO_TENANT
echo "keystone user-role-add \\
        --user-id $DEMO_USER \\
        --role-id $ANOTHER_ROLE \\
        --tenant-id $DEMO_TENANT"
keystone user-role-add --user-id $DEMO_USER --role-id $ANOTHER_ROLE --tenant-id $DEMO_TENANT

# TODO(termie): these two might be dubious
echo "keystone user-role-add \\
        --user-id $ADMIN_USER \\
        --role-id $KEYSTONEADMIN_ROLE \\
        --tenant-id $ADMIN_TENANT"
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONEADMIN_ROLE --tenant-id $ADMIN_TENANT
echo "keystone user-role-add \\
        --user-id $ADMIN_USER \\
        --role-id $KEYSTONESERVICE_ROLE \\
        --tenant-id $ADMIN_TENANT"
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONESERVICE_ROLE --tenant-id $ADMIN_TENANT


# The Member role is used by Horizon and Swift so we need to keep it:
echo "keystone role-create --name=Member"
MEMBER_ROLE=$(get_id keystone role-create --name=Member)
echo "keystone user-role-add \\
        --user-id $DEMO_USER \\
        --role-id $MEMBER_ROLE \\
        --tenant-id $DEMO_TENANT"
keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $DEMO_TENANT
#echo "keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $INVIS_TENANT"
#keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $INVIS_TENANT


# Configure service users/roles
### nova

echo "keystone user-create --name=nova --pass=nova --tenant-id=$SERVICE_TENANT --email=nova@example.com"
NOVA_USER=$(get_id keystone user-create --name=nova \
                                        --pass=nova \
                                        --tenant-id=$SERVICE_TENANT \
                                        --email=nova@example.com)
echo "keystone user-role-add \\
        --tenant-id $SERVICE_TENANT \\
        --user-id $NOVA_USER \\
        --role-id $ADMIN_ROLE"
keystone user-role-add --tenant-id $SERVICE_TENANT \
                       --user-id $NOVA_USER \
                       --role-id $ADMIN_ROLE
### glance
echo "keystone user-create \\
        --name=glance \\
        --pass=glance \\
        --tenant-id=$SERVICE_TENANT \\
        --email=glance@example.com"
GLANCE_USER=$(get_id keystone user-create --name=glance \
                                          --pass=glance \
                                          --tenant-id=$SERVICE_TENANT \
                                          --email=glance@example.com)
echo "keystone user-role-add \\
        --tenant-id $SERVICE_TENANT \\
        --user-id $GLANCE_USER \\
        --role-id $ADMIN_ROLE"
keystone user-role-add --tenant-id $SERVICE_TENANT \
                       --user-id $GLANCE_USER \
                       --role-id $ADMIN_ROLE

