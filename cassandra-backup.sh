#!/bin/bash

# Backup cassandra 2.x - 3.x and export the backup to S3
# Use this script on all nodes at the same time - cronjob recommended
# Install awscli before using, in case you upload to S3 (s3cmd works too, just adapt the script)

# Author Sebastian Sasu <sebi@nologin.ro>

# Please define and/or change these vars:
#
# AWS_DEFAULT_REGION
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# _BACKUP_DIR
# _S3_BUCKET
# _KEYSPACE
# _SNAP_DIR

set -e

export AWS_DEFAULT_REGION='' # us-east-1
export AWS_ACCESS_KEY_ID='' # AKIAI44QH8DHBEXAMPLE
export AWS_SECRET_ACCESS_KEY='' # je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

# Create the backup directory & define vars
mkdir -p /mnt/backup/cassandra
_BACKUP_DIR="" # "/mnt/backup/cassandra"
chown -R `whoami` ${_BACKUP_DIR} && chmod -R 775 ${_BACKUP_DIR}
_S3_BUCKET="" # "s3://yourbucket/"

# Define the keyspace and snapshot directory
_KEYSPACE="" # "mykeyspace"
_SNAP_DIR="" # "/mnt/cassandra/data/${_KEYSPACE}/*/snapshots/"

_NODETOOL=`which nodetool`
${_NODETOOL} snapshot -t ${_KEYSPACE}-$(hostname)-$(date +%F) ${_KEYSPACE}
wait

# Archive the snapshot
tar cvzf ${_BACKUP_DIR}/$(hostname)-$(date +%F).tar.gz ${_SNAP_DIR}

# Upload to S3 (adapt the script to whatever you're using, eg. FTP, RSYNC, SCP...)
# You can use a bandwidth limiter like trickle in case you have limited bandwidth
aws s3 cp ${_BACKUP_DIR}/$(hostname)-$(date +%F).tar.gz ${_S3_BUCKET}
wait

# Cleanup
${_NODETOOL} clearsnapshot && rm -rf ${_BACKUP_DIR}/$(hostname)-$(date +%F).tar.gz


unset AWS_DEFAULT_REGION
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY


echo "All done"
