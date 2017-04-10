#!/bin/bash
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
sudo usermod -aG docker $USER

# Enable docker at startup
sudo systemctl enable docker
