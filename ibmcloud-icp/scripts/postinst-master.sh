#!/bin/sh
/sbin/sfdisk /dev/xvdc << EOF
1,100GiB
,100GiB
;
EOF
/sbin/mkfs -t ext4 /dev/xvdc1
/sbin/mkfs -t ext4 /dev/xvdc2
/sbin/mkfs -t ext4 /dev/xvdc3
/bin/mkdir -p /var/lib/docker
/bin/mount /dev/xvdc1 /var/lib/docker
/bin/mkdir -p /var/lib/icp
/bin/mount /dev/xvdc2 /var/lib/icp
/bin/mkdir -p /storage
/bin/mount /dev/xvdc3 /storage
/bin/echo "/dev/xvdc1    /var/lib/docker    ext4    defaults    0  2" >> /etc/fstab
/bin/echo "/dev/xvdc2    /var/lib/icp    ext4    defaults    0  2" >> /etc/fstab
/bin/echo "/dev/xvdc3    /storage    ext4    defaults    0  2" >> /etc/fstab