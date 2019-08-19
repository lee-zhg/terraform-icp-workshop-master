#!/bin/bash

LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-aT0pSecr8t}"
ICP_ADMIN_PASSWORD="${ICP_ADMIN_PASSWORD:-Th#nk19icp}"
INPUT_FILE="${INPUT_FILE:-users.csv}"

print_help(){
cat << EOF
Usage: $0 -ip=IPADDR -c=CLUSTER_URL [OPTIONS]...

Configure ldap server. Run this from the users directory.

Mandatory arguments to long options are mandatory for short options too.
  -c=,  --cluster-url=STRING         STRING full URL to cluster for login
  -ip=, --ldap-priv-ip=IPADDR        Private IPADDR of ldap server
        --ldap-admin-password=STRING password for LDAP admin dn
        --icp-admin-password=STRING password for admin user for ICP 
  -i=,  --input-file=STRING          STRING name of input .csv file
                                         defaults to users.csv
  -h   --help                        display this help and exit

EOF
}

for OPT in "$@"; do
    case "$OPT" in
        -ip=*|--ldap-priv-ip=*)
            LDAP_PRIV_IP="${OPT#*=}"
            ;;
        --ldap-admin-password=*)
            LDAP_ADMIN_PASSWORD="${OPT#*=}"
            ;;
        --icp-admin-password=*)
            ICP_ADMIN_PASSWORD="${OPT#*=}"
            ;;
        -i=*|--input-file=*)
            INPUT_FILE="${OPT#*=}"
            ;;
        -c=*|--cluster-url=*)
            CLUSTER_URL="${OPT#*=}"
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unexpected flag $OPT"
            print_help
            exit 2
            ;;
    esac
done

if [[ -z $LDAP_PRIV_IP ]]; then
    echo "Error: Private IP address for LDAP server not specified"
    print_help
    exit 3
fi

if [[ -z $CLUSTER_URL ]]; then
    echo "Error: Private IP address for LDAP server not specified"
    print_help
    exit 3
fi

if [[ ! -f $INPUT_FILE ]]; then
    echo "Error: please run this script from the users directory"
    print_help
    exit 3
fi

count=$(($( cat $INPUT_FILE | wc -l ) - 1 ))

# create ICP configuration command script file
# build file using parameterization
cat << EOF > icp_ldap.sh
#!/bin/sh
cloudctl login -a $CLUSTER_URL -u admin -p $ICP_ADMIN_PASSWORD -n default --skip-ssl-validation

# add ldap connection
cloudctl iam ldap-create icpldap --basedn 'dc=icp' --server "ldap://$LDAP_PRIV_IP:389" --group-filter '(&(cn=%v)(objectclass=groupOfUniqueNames))' \
--group-id-map '*:cn' --group-member-id-map 'groupOfUniqueNames:uniqueMember' --user-filter '(&(uid=%v)(objectclass=inetOrgPerson))'            \
--user-id-map '*:uid' --binddn 'cn=admin,dc=icp' --binddn-password "$LDAP_ADMIN_PASSWORD"

# add ldap-based admin user
cloudctl iam team-create admgrp
yes | cloudctl iam user-import -u "suser001"
cloudctl iam team-add-users admgrp "ClusterAdministrator" -u suser001

touch /root/icp_ldap_added
EOF

# avoid parameterization for these commands
cat << 'EOF' > icp_users.sh
#!/bin/sh
count=$1

# add namespaces and users
for num in $(seq -f "%03g" $count); do kubectl create namespace devnamespace$num; done
for num in $(seq -f "%03g" $count); do cloudctl iam team-create team$num; done
yes | cloudctl iam user-import -u "user*"
for num in $(seq -f "%03g" $count); do cloudctl iam team-add-users team$num Administrator -u user$num; done

# add resources for teams
for num in $(seq -f "%03g" $count); do cloudctl iam resource-add team$num -r crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-blockchain-platform-dev,\
crn:v1:icp:private:k8:mycluster:n/devnamespace$num:::,crn:v1:icp:private:k8:mycluster:n/kube-system:::,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-repos:,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-datapower-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-db2oltp-dev,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-eventstreams-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-hazelcast-dev,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-glusterfs,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-istio,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-nodejs-sample,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-microclimate,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-mongodb-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-blockchain-platform-remote-peer,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-websphere-liberty,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-mariadb-dev,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-jenkins-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-websphere-traditional,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-nginx-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-swift-sample,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-redis-ha-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-open-liberty,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-transadv-dev,crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-rabbitmq-dev,\
crn:v1:icp:private:helm-catalog:mycluster:r/ibm-charts::helm-charts:ibm-postgres-dev ; done

# revoke kube-system for teams
for num in $(seq -f "%03g" 1 30); do cloudctl iam resource-rm team$num -r crn:v1:icp:private:k8:mycluster:n/kube-system::: ; done

# relax pod policies across clusters
cloudctl cm psp-default-set unrestricted
EOF

# run playbook to transfer files to ldap and run setup script
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i devvm_host ../scripts/setupICP.yml --extra-vars "count=$count"

# clean up
rm icp_ldap.sh
rm icp_users.sh






