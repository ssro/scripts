#!/bin/bash

# Add 4G of swapfile on CentOS or Debian systems


centos_swap() {
  sudo dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile

  echo -e '/swapfile\t none\t swap\t sw\t 0 0' | sudo tee --append /etc/fstab > /dev/null
}

debian_swap() {
  sudo fallocate -l 4G /swapfile \
  && sudo chmod 600 /swapfile \
  && sudo mkswap /swapfile \
  && sudo swapon /swapfile

echo -e '/swapfile\t none\t swap\t sw\t 0 0' | sudo tee --append /etc/fstab > /dev/null
}



echo ""
echo "My Operating System is CentOS/Debian (please input c or d): "
echo ""
read -r os

if [[ "$os" == "c" ]]; then
  echo "Creating swap for CentOS..."
  centos_swap
elif [[ "$os" == "d" ]]; then
    echo "Creating swap for Debian..."
    debian_swap
else "Unsupported OS. Exiting..."
  exit 0
fi
