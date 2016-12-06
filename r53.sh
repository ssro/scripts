#!/bin/bash

# This script will backup all your route 53 zones in one shot and upload them
# to an s3 bucket of your choice.
# The output is BIND compatible (possibly NSD).
# Make sure you have cli53 & awscli installed on your system

# Author: Sebastian Sasu <sebi@nologin.ro>

set -e -u

# Create and export the backup dir
mkdir $HOME/domains-`date +%F`
_DEST_DIR=$HOME/domains-`date +%F`

# Define the S3 bucket
_BUCKET='' # mybuycket/r53

# Export AWS variables or set them up in your shell ENV
export AWS_DEFAULT_REGION='' # us-east-1
export AWS_ACCESS_KEY_ID='' # AKIAI44QH8DHBEXAMPLE
export AWS_SECRET_ACCESS_KEY='' # je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

domain=$(cli53 list|awk '{if (NR!=1) {print $2}}'|sed 's/\.[^.]*$//')

for i in $domain; do
  cli53 export -f $i > $_DEST_DIR/$i.zone
done

tar cvzf $_DEST_DIR.tar.gz $_DEST_DIR
aws s3 cp $_DEST_DIR.tar.gz s3://$_BUCKET/

# Cleanup
rm -rf $_DEST_DIR $_DEST_DIR.tar.gz

# If you've exported AWS env vars through this script, unset them
unset AWS_DEFAULT_REGION
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

