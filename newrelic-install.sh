#!/bin/bash
# Install NewRelic agent on Centos 6, 7 - 64-bit
# Optional - enable docker monitoring

# Author Sebastian Sasu <sebi@nologin.ro>

rpm_url="https://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm"

sudo yum -y install "$rpm_url" \
  && yum -y install newrelic-sysmond

echo ""
echo "Enter your license key: "
read license

sudo nrsysmond-config --set license_key="$license"

echo "Starting & enabling newrelic monitor...."
sudo /etc/init.d/newrelic-sysmond start
sudo /sbin/chkconfig newrelic-sysmond on

# Enable docker
# sudo groupadd -r docker
echo ""
echo "Enable docker monitoring? y/n"
read answer

if [[ "$answer" != "y" ]]; then
  exit 0
else sudo usermod -a -G docker newrelic && sudo /etc/init.d/newrelic-sysmond restart
fi
