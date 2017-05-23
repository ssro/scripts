#!/bin/bash

# Create swap space on a CentOS7 EC2 machine (or bare metal)
# Best suited for XFS filesystem
# Swap file size is 4G

sudo dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

echo -e '/swapfile\t none\t swap\t sw\t 0 0' | sudo tee --append /etc/fstab > /dev/null
