#!/bin/sh
#
# replace this with IP of the master for ICP
export MASTERIP=127.0.0.1

# set up Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common ldap-utils socat
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce python

# set up IBM Cloud stand-alone cli
curl -fsSL https://clis.ng.bluemix.net/install/linux | sh

# set up cloud private cli
curl -kLo cloudctl-linux-amd64-3.1.1-973 https://${MASTERIP}:8443/api/cli/cloudctl-linux-amd64
chmod 755 cloudctl-linux-amd64-3.1.1-973
mv cloudctl-linux-amd64-3.1.1-973 /usr/local/bin/cloudctl

# set up kubectl
curl -kLo kubectl-linux-amd64-v1.11.1 https://${MASTERIP}:8443/api/cli/kubectl-linux-amd64
chmod 755 kubectl-linux-amd64-v1.11.1
mv kubectl-linux-amd64-v1.11.1 /usr/local/bin/kubectl

# set up helm
curl -kLo helm-linux-amd64-v2.9.1.tar.gz https://${MASTERIP}:8443/api/cli/helm-linux-amd64.tar.gz
tar -xzf helm-linux-amd64-v2.9.1.tar.gz
mv linux-amd64/helm /usr/local/bin
rm -rf helm-linux-amd64-v2.9.1.tar.gz linux-amd64

# maven / java
apt-get install -y openjdk-8-jdk maven
