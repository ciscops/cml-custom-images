#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Disable the release upgrader
echo "==> Disabling automatic release upgrades"
/bin/sed -i 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

echo "==> Gathering OS release info"
. /etc/lsb-release

#if [[ $DISTRIB_RELEASE == 20.04 ]]; then
  echo "==> Disabling periodic apt upgrades"
  echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic
#fi

echo "==> Updating package index from repositories"
# Update list of available packages
/bin/apt-get -qq update

if [[ $UPDATE_OS  =~ true || $UPDATE_OS =~ 1 || $UPDATE_OS =~ yes ]]; then
    echo "==> Upgrading base system"
    /bin/apt-get -qq -y dist-upgrade
fi