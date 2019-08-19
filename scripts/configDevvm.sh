#!/bin/bash

INPUT_FILE="${INPUT_FILE:-users.csv}"

print_help(){
cat << EOF
Usage: $0 -ip=IPADDR [OPTIONS]...

Configure developer vms. Run this from the users directory.

Mandatory arguments to long options are mandatory for short options too.
  -ip=, --ldap-ip=IPADDR             IPADDR of developer vm
  -i=,  --input-file=STRING          STRING name of input .csv file
                                         defaults to users.csv
  -h   --help                        display this help and exit

EOF
}

for OPT in "$@"; do
    case "$OPT" in
        -ip=*|--ldap-ip=*)
            DEVVM_IP="${OPT#*=}"
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

if [[ -z $DEVVM_IP ]]; then
    echo "Error: IP address for Developer VM not specified"
    print_help
    exit 3
fi

if [[ ! -f userldif.awk ]]; then
    echo "Error: please run this script from the users directory"
    print_help
    exit 3
fi

# stage user csv file to scripts/files
mkdir -p ../scripts/files
cp $INPUT_FILE ../scripts/files/users.csv

# create inventory file
cat << EOF > devvm_host
[devvm]
$DEVVM_IP
EOF

# create ldap server command script file
# build file for POST
cat << 'EOF' > ../scripts/files/user_setup.sh
#!/bin/bash
for user in $(awk -F "," '{ if(NR > 1)print $1 }' < users.csv); do /root/provision-user-passwd.sh $user; done
for combo in $(awk -F "," '{ if(NR > 1)print $1":"$2 }' < users.csv); do echo $combo | chpasswd; done
touch /root/users-added
EOF

# run playbook to transfer files to ldap and run setup script
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i devvm_host ../scripts/setupDevvm.yml

# clean up ldap setup script and icp admin user ldif
rm ../scripts/files/user_setup.sh
rm ../scripts/files/users.csv





