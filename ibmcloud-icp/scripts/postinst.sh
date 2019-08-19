#!/bin/sh
/bin/echo 'type=83' | /sbin/sfdisk /dev/xvdc
/sbin/mkfs -t ext4 /dev/xvdc1
/bin/mkdir -p /var/lib/docker
/bin/mount /dev/xvdc1 /var/lib/docker
/bin/echo "/dev/xvdc1    /var/lib/docker    ext4    defaults    0  2" >> /etc/fstab