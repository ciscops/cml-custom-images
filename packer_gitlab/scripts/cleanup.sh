#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

printf "==> Cleanup\n"

# Various OS-related stuff
/bin/apt-get -qq -y autoremove --purge
/bin/apt-get -qq -y autoclean
/bin/apt-get -qq -y clean
/bin/rm -rf /var/lib/apt/lists/{apt,cache,dpkg,log} /tmp/* /var/tmp/*
/bin/cp /dev/null /etc/machine-id

# Force SSH keys to be regenerated
/bin/shred -u /etc/ssh/*_key /etc/ssh/*_key.pub

# cloud-init should run upon next boot
/usr/bin/cloud-init clean --logs

# Make sure all filesystem changes are flushed
/bin/sync
exit 0
