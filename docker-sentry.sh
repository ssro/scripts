#!/bin/bash
# Quick and dirty install of docker-sentry (new install) on Centos 7

# Use docker-install.sh from this repo to install docker engine
# If this gets deployed on AWS EC2, use a machine with at least 2 GB of RAM
# Same amount of RAM applies for bare metal

# Author Sebastian Sasu <sebi@nologin.ro>

# Install etcd3 for key value storage

sudo yum -y install epel && sudo yum -y update
sudo yum -y install etcd3
sudo systemctl enable etcd && sudo systemctl start etcd

#-- Start Redis preparation
# Add this to /etc/rc.local. For now we'll echo it
sudo bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
# Add this to /etc/sysctl.conf. For now we'll change this on the fly
sudo sysctl -w vm.overcommit_memory=1
sudo sysctl -w net.core.somaxconn=65535
#-- End Redis preparation

# Container directories for data persistence

# NOTE: The following mkdir command is not necessary
# since the folders will be created automatically
# mkdir -p $HOME/docker-sentry/{postgres,sentry,redis}

#-- Start etcd VARS
# Modify/add/remove values as needed

etcdctl set /sentry/POSTGRES_PASSWORD supersecret
etcdctl set /sentry/POSTGRES_USER sentry
etcdctl set /sentry/PGDATA /var/lib/postgresql/data/pgdata
etcdctl set /sentry/PG_DIR $HOME/sentry/postgres
etcdctl set /sentry/REDIS_DIR $HOME/sentry/redis
etcdctl set /sentry/SENTRY_DIR $HOME/sentry/sentry
etcdctl set /sentry/SENTRY_SINGLE_ORGANIZATION False
etcdctl set /sentry/SENTRY_SERVER_EMAIL sentry@example.com
etcdctl set /sentry/SENTRY_EMAIL_HOST smtp.example.com
etcdctl set /sentry/SENTRY_EMAIL_PASSWORD super-secret
etcdctl set /sentry/SENTRY_EMAIL_USER mailuser
etcdctl set /sentry/SENTRY_EMAIL_PORT 587
etcdctl set /sentry/SENTRY_EMAIL_USE_TLS True
#-- End VARS

# Start redis
docker run -d --name redis --sysctl=net.core.somaxconn=65535 -v $(etcdctl get /sentry/REDIS_DIR):/data redis

# Start postgres
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=$(etcdctl get /sentry/POSTGRES_PASSWORD) \
  -e POSTGRES_USER=$(etcdctl get /sentry/POSTGRES_USER) \
  -e PGDATA=$(etcdctl get /sentry/PGDATA) \
  -v $(etcdctl get /sentry/PG_DIR):/var/lib/postgresql/data/pgdata \
  postgres

sleep 10

# Generate sentry key & add it to etcd
etcdctl set /sentry/SENTRY_SECRET_KEY $(docker run --rm sentry config generate-secret-key)

# Upgrade database
docker run -it --rm \
  -e SENTRY_SECRET_KEY=$(etcdctl get /sentry/SENTRY_SECRET_KEY) \
  -v $(etcdctl get /sentry/SENTRY_DIR):/var/lib/sentry/files \
  --link postgres:postgres \
  --link redis:redis \
  sentry upgrade


# Start sentry
docker run -d -p 9000:9000 \
  --name sentry \
  -e SENTRY_SECRET_KEY=$(etcdctl get /sentry/SENTRY_SECRET_KEY) \
  -e SENTRY_SINGLE_ORGANIZATION=$(etcdctl get /sentry/SENTRY_SINGLE_ORGANIZATION) \
  -e SENTRY_SERVER_EMAIL=$(etcdctl get /sentry/SENTRY_SERVER_EMAIL) \
  -e SENTRY_EMAIL_HOST=$(etcdctl get /sentry/SENTRY_EMAIL_HOST) \
  -e SENTRY_EMAIL_PASSWORD=$(etcdctl get /sentry/SENTRY_EMAIL_PASSWORD) \
  -e SENTRY_EMAIL_USER=$(etcdctl get /sentry/SENTRY_EMAIL_USER) \
  -e SENTRY_EMAIL_PORT=$(etcdctl get /sentry/SENTRY_EMAIL_PORT) \
  -e SENTRY_EMAIL_USE_TLS=$(etcdctl get /sentry/SENTRY_EMAIL_USE_TLS) \
  -v $(etcdctl get /sentry/SENTRY_DIR):/var/lib/sentry/files \
  --link redis:redis \
  --link postgres:postgres \
  sentry

# Start sentry cron
docker run -d --name sentry-cron \
  -v $(etcdctl get /sentry/SENTRY_DIR):/var/lib/sentry/files \
  -e SENTRY_SECRET_KEY=$(etcdctl get /sentry/SENTRY_SECRET_KEY) \
  --link postgres:postgres \
  --link redis:redis \
  sentry run cron

# Start worker (you can start as many workers as you want, just give them different names (--name))
docker run -d --name sentry-worker-1 \
  -v $(etcdctl get /sentry/SENTRY_DIR):/var/lib/sentry/files \
  -e SENTRY_SECRET_KEY=$(etcdctl get /sentry/SENTRY_SECRET_KEY) \
  --link postgres:postgres \
  --link redis:redis \
  sentry run worker

# Access your sentry installation at http://machine_ip:9000/
# The use of nginx proxy w/ SSL is highly recommended

# If you don't want users to register, you need to add to sentry.conf.py
# SENTRY_FEATURES['auth:register'] = False
# For this you will need to clone https://github.com/getsentry/docker-sentry.git
# edit and rebuild sentry container
