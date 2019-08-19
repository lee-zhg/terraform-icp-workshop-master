#!/bin/sh
# add user copy public key to authorized_keys
adduser --disabled-password --gecos '' $1
mkdir -p /home/$1/.ssh
cp creds/$1.pub /home/$1/.ssh/authorized_keys
chown -R $1:$1 /home/$1/.ssh
chmod 700 /home/$1/.ssh
chmod 600 /home/$1/.ssh/authorized_keys
usermod -aG docker $1
su - $1
ibmcloud plugin install cloud-functions