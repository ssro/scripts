#!/bin/bash

# Docker automated installation for CentOS 7 or Debian Stretch/Jessie

centos_docker() {
# Docker automated installation on CentOS 7
# Install epel repo, yum-utils and update system
  sudo yum -y install epel-release yum-utils \
    && sudo yum -y update

# Remove old docker installs if any
  sudo yum -y remove docker \
    docker-common \
    container-selinux \
    docker-selinux \
    docker-engine

# Add docker-ce repo to yum
  sudo yum-config-manager -y \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Update yum package index
  sudo yum -y makecache fast

# Install docker-ce
  sudo yum -y install docker-ce

# Add current user to docker group
  sudo usermod -aG docker "$USER"

# Enable docker at startup
  sudo systemctl enable docker

# Enable overlay2 storage driver on xfs (kernel 4.x)
#  mkdir /etc/docker
# cat <<EOF > /etc/docker/daemon.json
# {
#   "storage-driver": "overlay2",
#   "storage-opts": [
#     "overlay2.override_kernel_check=true"
#   ]
# }
# EOF

}

debian_docker() {
  # Docker automated installation on debian stretch and/or jessie

  # Start clean (remove old docker versions, if any)
  sudo apt-get -y remove docker docker-engine docker.io

  sudo apt-get -y update && sudo apt-get -y install \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg2 \
       software-properties-common

  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/debian \
     $(lsb_release -cs) \
     stable" \
     && sudo apt-get -y update

  # Install docker

  sudo apt-get -y install docker-ce

  # Post install

  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker || exit 0

}

echo ""
echo "My Operating System is (c)entOS/(d)ebian: "
echo ""
read -r os

if [[ "$os" == "c" ]]; then
  echo "Installing Docker on CentOS..."
  centos_docker
elif [[ "$os" == "d" ]]; then
    echo "Installing Docker on Debian..."
    debian_docker
else "Unsupported OS. Exiting..."
  exit 0
fi

echo -e "You need to re-login to be able to start docker as a regular user\n"
