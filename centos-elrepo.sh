#!/bin/bash

# Add ELRepo repository on CentOS 6 & 7 and install mainline or
# long term kernel

# Author Sebastian Sasu <sebi@nologin.ro>

set -e -x

c6="http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm"
c7="http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm"

release=$(rpm --query centos-release|cut -d "-" -f3)

if [[ "$release" -ne "7" ]]; then
  echo "Installing packages for CentOS 6...."
  sudo yum -y install "$c6"
else echo "Installing packages for CentOS 7..."
  sudo yum -y install "$c7"
fi


# Install kernel

echo "Which kernel should I install? Mainline or long-term? (ml/lt)"
read -r kernel

sudo yum -y --enablerepo=elrepo-kernel install kernel-"$kernel"


if [[ "$release" -ne "7" ]]; then
  echo "CentOS 6 detected. Modyfing boot parameters..."
  sudo sed -i 's/default=1/default=0/' /boot/grub/grub.conf
  sudo sed -i '/default=0/a fallback=1' /boot/grub/grub.conf
else echo "CentOS 7 detected. Modifying boot parameters..."
  sudo grub2-set-default 0 \
    && sudo grub2-mkconfig -o /boot/grub2/grub.cfg
fi
echo ""
echo "######################################################"
echo " >> Reboot your machine for changes to take effect << "
echo "######################################################"
echo ""
