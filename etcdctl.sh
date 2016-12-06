#!/bin/bash

# Backup etcd key values to file

_ETCD_DIR=$HOME/etcd-bk

# Start clean
rm -rf $_ETCD_DIR
mkdir $_ETCD_DIR

for i in $(etcdctl ls / --recursive );
do
echo -n "etcdctl get ${i} "
etcdctl get $i
done > $_ETCD_DIR/etcdctl-backup-`uname -n`

