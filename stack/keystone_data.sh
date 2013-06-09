#!/bin/bash
#
# Initial data for Keystone using python-keystoneclient
#
# Tenant               User      Roles
# ------------------------------------------------------------------
# admin                admin     admin
# service              glance    admin
# service              nova      admin, [ResellerAdmin (swift only)]
# service              quantum   admin        # if enabled
# service              swift     admin        # if enabled
# demo                 admin     admin
# demo                 demo      Member, anotherrole

## invisible_to_admin   demo      Member
## Tempest Only:
## alt_demo             alt_demo  Member
#
# Variables set before calling this script:
# SERVICE_TOKEN - aka admin_token in keystone.conf
# SERVICE_ENDPOINT - local Keystone admin endpoint
# SERVICE_TENANT_NAME - name of tenant containing service accounts
# ENABLED_SERVICES - stack.sh's list of services to start
# DEVSTACK_DIR - Top-level DevStack directory

ADMIN_PASSWORD=admin
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$ADMIN_PASSWORD}
#export SERVICE_TOKEN=$SERVICE_TOKEN
#export SERVICE_ENDPOINT=$SERVICE_ENDPOINT
export SERVICE_TOKEN=ADMIN
export SERVICE_ENDPOINT=http://192.168.0.110:35357/v2.0
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}

function get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
ADMIN_TENANT=$(get_id keystone tenant-create --name=admin)
SERVICE_TENANT=$(get_id keystone tenant-create --name=$SERVICE_TENANT_NAME)
DEMO_TENANT=$(get_id keystone tenant-create --name=demo)


# Users
ADMIN_USER=$(get_id keystone user-create --name=admin \
                                         --pass=admin \
                                         --email=admin@example.com)
DEMO_USER=$(get_id keystone user-create --name=demo \
                                        --pass=demo \
                                        --email=demo@example.com)





# Roles
ADMIN_ROLE=$(get_id keystone role-create --name=admin)
KEYSTONEADMIN_ROLE=$(get_id keystone role-create --name=KeystoneAdmin)
KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name=KeystoneServiceAdmin)
# ANOTHER_ROLE demonstrates that an arbitrary role may be created and used
# TODO(sleepsonthefloor): show how this can be used for rbac in the future!
ANOTHER_ROLE=$(get_id keystone role-create --name=anotherrole)


# Add Roles to Users in Tenants
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $DEMO_TENANT
keystone user-role-add --user-id $DEMO_USER --role-id $ANOTHER_ROLE --tenant-id $DEMO_TENANT

# TODO(termie): these two might be dubious
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONEADMIN_ROLE --tenant-id $ADMIN_TENANT
keystone user-role-add --user-id $ADMIN_USER --role-id $KEYSTONESERVICE_ROLE --tenant-id $ADMIN_TENANT


# The Member role is used by Horizon and Swift so we need to keep it:
MEMBER_ROLE=$(get_id keystone role-create --name=Member)
keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $DEMO_TENANT
keystone user-role-add --user-id $DEMO_USER --role-id $MEMBER_ROLE --tenant-id $INVIS_TENANT


# Configure service users/roles
### nova
NOVA_USER=$(get_id keystone user-create --name=nova \
                                        --pass=nova \
                                        --tenant-id=$SERVICE_TENANT \
                                        --email=nova@example.com)
keystone user-role-add --tenant-id $SERVICE_TENANT \
                       --user-id $NOVA_USER \
                       --role-id $ADMIN_ROLE
### glance
GLANCE_USER=$(get_id keystone user-create --name=glance \
                                          --pass=glance \
                                          --tenant-id=$SERVICE_TENANT \
                                          --email=glance@example.com)
keystone user-role-add --tenant-id $SERVICE_TENANT \
                       --user-id $GLANCE_USER \
                       --role-id $ADMIN_ROLE



#-------------------------------------#
### swift
if [[ "$ENABLED_SERVICES" =~ "swift" ]]; then
    SWIFT_USER=$(get_id keystone user-create --name=swift \
                                             --pass="$SERVICE_PASSWORD" \
                                             --tenant-id $SERVICE_TENANT \
                                             --email=swift@example.com)
    keystone user-role-add --tenant-id $SERVICE_TENANT \
                           --user-id $SWIFT_USER \
                           --role-id $ADMIN_ROLE
    # Nova needs ResellerAdmin role to download images when accessing
    # swift through the s3 api. The admin role in swift allows a user
    # to act as an admin for their tenant, but ResellerAdmin is needed
    # for a user to act as any tenant. The name of this role is also
    # configurable in swift-proxy.conf
    RESELLER_ROLE=$(get_id keystone role-create --name=ResellerAdmin)
    keystone user-role-add --tenant-id $SERVICE_TENANT \
                           --user-id $NOVA_USER \
                           --role-id $RESELLER_ROLE
fi

### quantum
if [[ "$ENABLED_SERVICES" =~ "quantum" ]]; then
    QUANTUM_USER=$(get_id keystone user-create --name=quantum \
                                               --pass="$SERVICE_PASSWORD" \
                                               --tenant-id $SERVICE_TENANT \
                                               --email=quantum@example.com)
    keystone user-role-add --tenant-id $SERVICE_TENANT \
                           --user-id $QUANTUM_USER \
                           --role-id $ADMIN_ROLE
fi

### tempest
if [[ "$ENABLED_SERVICES" =~ "tempest" ]]; then
    # Tempest has some tests that validate various authorization checks
    # between two regular users in separate tenants
    ALT_DEMO_TENANT=$(get_id keystone tenant-create --name=alt_demo)
    ALT_DEMO_USER=$(get_id keystone user-create --name=alt_demo \
                                        --pass="$ADMIN_PASSWORD" \
                                        --email=alt_demo@example.com)
    keystone user-role-add --user-id $ALT_DEMO_USER --role-id $MEMBER_ROLE --tenant-id $ALT_DEMO_TENANT
fi
