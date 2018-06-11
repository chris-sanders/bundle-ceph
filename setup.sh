#!/bin/bash

# CONTAINER=$1
CEPH_UNIT=${1:-ceph-osd/0}
MACHINE=${2:-0}
CONTAINER=$(juju status | grep "^$(juju status | grep "$CEPH_UNIT" | awk '{print $4}')" | awk '{print $4}')

# Add udev rules to container
juju scp ./99-lxd-mnt.rules $CEPH_UNIT:/home/ubuntu/
juju run --unit $CEPH_UNIT "mv /home/ubuntu/99-lxd-mnt.rules /etc/udev/rules.d/"
juju run --unit $CEPH_UNIT "chown root:root /etc/udev/rules.d/99-lxd-mnt.rules"

# Setup container profile
juju scp ./ceph.config $MACHINE:/home/ubuntu/
juju run --machine $MACHINE "cp /home/ubuntu/ceph.config /tmp/"
juju run --machine $MACHINE "sudo lxc profile create ceph 2>/dev/null"
juju run --machine $MACHINE "sudo lxc profile edit ceph < /tmp/ceph.config" 

# Apply profile
juju run --machine $MACHINE "sudo lxc profile apply $CONTAINER ceph"

# Restart lxd container
juju run --machine $MACHINE "sudo lxc restart $CONTAINER"

# Add relation to ceph-mon
juju add-relation ceph-osd ceph-mon
