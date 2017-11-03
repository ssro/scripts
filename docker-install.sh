#!/bin/bash

# Docker automated installation for CentOS 7, Debian Stretch/Jessie or Ubuntu (14.04, 16.04)

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
#EOF

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

  # Stop docker and add overlay2 storage driver
  sudo systemctl stop docker && sudo cp -au /var/lib/docker /var/lib/docker.bk

  sudo bash -c 'cat <<EOF > /etc/docker/daemon.json
  {
    "storage-driver": "overlay2"
  }
EOF'
  # Start docker
  sudo systemctl start docker
}

ubuntu_docker() {
  # Update everything
  sudo apt-get -y update && sudo apt-get -y dist-upgrade

  # Remove previous installs of docker
  sudo apt-get -y remove docker docker-engine docker.io

  # Install prerequisites
  sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"

  # Install docker & enable it at boot time
  sudo apt-get -y update \
    && sudo apt-get -y install docker-ce \
    && sudo usermod -aG docker $USER \
    && sudo systemctl enable docker || exit 0

  # Logout and relogin to your machine or reboot

  # Stop docker and add overlay2 storage driver
  sudo systemctl stop docker && sudo cp -au /var/lib/docker /var/lib/docker.bk

  sudo bash -c 'cat <<EOF > /etc/docker/daemon.json
  {
    "storage-driver": "overlay2"
  }
EOF'

  # Start docker
  sudo systemctl start docker
}
echo -e "\n"
echo -e "My Operating System is \033[1m(c)\033[0mentOS/\033[1m(d)\033[0mebian/\033[1m(u)\033[0mbuntu: \n"

read -r os

if [[ "$os" == "c" ]]; then
  echo "Installing Docker on CentOS..."
  centos_docker
elif [[ "$os" == "d" ]]; then
    echo "Installing Docker on Debian..."
    debian_docker
elif [[ "$os" == "u" ]]; then
    echo "Installing Docker on Ubuntu..."
    ubuntu_docker
else "Your OS is something that we don't support in this script. Please create a pull request..."
  exit 0
fi
echo -e "\n"
echo -e "\033[1mYou need to re-login to be able to start docker as a regular user\033[0\n"
