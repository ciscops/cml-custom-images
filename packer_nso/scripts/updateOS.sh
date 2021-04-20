#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Disable the release upgrader
printf "==> Disabling automatic release upgrades\n"
/bin/sed -i 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

printf "==> Gathering OS release info\n"
. /etc/lsb-release

#if [[ $DISTRIB_RELEASE == 20.04 ]]; then
  printf "==> Disabling periodic apt upgrades\n"
  printf 'APT::Periodic::Enable "0";\n' >> /etc/apt/apt.conf.d/10periodic
#fi

printf "==> Updating package index from repositories\n"
# Update list of available packages
/bin/apt-get -qq update

if [[ $UPDATE_OS =~ true || $UPDATE_OS =~ 1 || $UPDATE_OS =~ yes ]]; then
    printf "==> Upgrading base system\n"
    /bin/apt-get -qq -y dist-upgrade
fi

exit 0
