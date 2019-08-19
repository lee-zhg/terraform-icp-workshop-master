#!/bin/bash

LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-aT0pSecr8t}"
ICP_ADMIN_PASSWORD="${ICP_ADMIN_PASSWORD:-Time4fun}"
INPUT_FILE="${INPUT_FILE:-users.csv}"

print_help(){
cat << EOF
Usage: $0 -ip=IPADDR [OPTIONS]...

Configure ldap server. Run this from the users directory.

Mandatory arguments to long options are mandatory for short options too.
  -ip=, --ldap-ip=IPADDR             IPADDR of ldap server
        --ldap-admin-password=STRING password for LDAP admin dn
  -i=,  --input-file=STRING          STRING name of input .csv file
                                         defaults to users.csv
  -h   --help                        display this help and exit

EOF
}

for OPT in "$@"; do
    case "$OPT" in
        -ip=*|--ldap-ip=*)
            LDAP_IP="${OPT#*=}"
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

if [[ -z $LDAP_IP ]]; then
    echo "Error: IP address for LDAP server not specified"
    print_help
    exit 3
fi

if [[ ! -f userldif.awk ]]; then
    echo "Error: please run this script from the users directory"
    print_help
    exit 3
fi

# format user csv into ldif for upload to LDAP
awk -f userldif.awk <  $INPUT_FILE > bulkusers.ldif

# create inventory file
cat << EOF > ldap_host
[ldap]
$LDAP_IP
EOF

# create ICP ldap-based admin user
cat << EOF > susers.ldif
dn: cn=Super User01,dc=icp
uid: suser001
cn: Super User01
sn: User01
objectClass: top
objectClass: inetOrgPerson
userPassword: $ICP_ADMIN_PASSWORD
EOF

# create ldap server command script file
# build file for POST
cat << EOF > ldap_setup.sh
#!/bin/sh
docker run -v /root/ldap:/var/lib/ldap -v /root/slapd.d:/etc/ldap/slapd.d --network host --name icpldap --env LDAP_ORGANISATION="ICP" --env LDAP_DOMAIN="icp" --env LDAP_ADMIN_PASSWORD="$LDAP_ADMIN_PASSWORD" --detach osixia/openldap:1.2.1
sleep 20
ldapadd -x -H ldap://localhost -D "cn=admin,dc=icp" -w $LDAP_ADMIN_PASSWORD -f susers.ldif
ldapadd -x -H ldap://localhost -D "cn=admin,dc=icp" -w $LDAP_ADMIN_PASSWORD -f group.ldif
ldapadd -x -H ldap://localhost -D "cn=admin,dc=icp" -w $LDAP_ADMIN_PASSWORD -f bulkusers.ldif
EOF

# run playbook to transfer files to ldap and run setup script
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ldap_host ../scripts/setupLdap.yml

# clean up ldap setup script and icp admin user ldif
rm ldap_setup.sh
rm susers.ldif





