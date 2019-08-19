#!/bin/sh
# add user run setup for cloud functions cli for the user
adduser --disabled-password --gecos '' $1
usermod -aG docker $1
sudo -u $1 -i ibmcloud plugin install cloud-functions
