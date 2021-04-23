#!/bin/bash

nsoInstallerSigned=nso-${NSO_VER}.linux.x86_64.signed.bin
nsoInstaller=nso-${NSO_VER}.linux.x86_64.installer.bin

# If using the signed wrapper, unpack the inner installer first
if [[ -f $UPLOAD_DIR/$nsoInstallerSigned ]]; then
  tmpDir=`/usr/bin/mktemp -d $UPLOAD_DIR/nsoInstall.XXXX`
  (cd $tmpDir; sh $UPLOAD_DIR/$nsoInstallerSigned --skip-verification >> /dev/null)
  /bin/mv $tmpDir/$nsoInstaller $UPLOAD_DIR
  /bin/rm -rf $tmpDir $UPLOAD_DIR/$nsoInstallerSigned
fi

nso_install_opts="$INSTALL_DIR --${NSO_INSTALL_TYPE}-install"
nso_package_dir=$INSTALL_DIR/packages/neds

# Use the default directories if doing system install
if [[ $NSO_INSTALL_TYPE =~ system ]]; then
  INSTALL_DIR=/opt/ncs/ncs-${NSO_VER}
  nso_install_opts="--${NSO_INSTALL_TYPE}-install"
  nso_package_dir=/var/opt/ncs/packages
else
  /bin/mkdir -p $INSTALL_DIR
fi

printf "==> Installing NSO $NSO_VER to $INSTALL_DIR\n"
/bin/sh $UPLOAD_DIR/$nsoInstaller $nso_install_opts

# Misc stuff based on install type
if [[ $NSO_INSTALL_TYPE =~ local ]]; then
  # Normally these keys should be RW only for user, but may need R for potentially random user
  /bin/chmod 0644 $INSTALL_DIR/netsim/confd/etc/confd/ssh/ssh_host_rsa_key
  /bin/chmod 0644 $INSTALL_DIR/etc/ncs/ssh/ssh_host_ed25519_key
else
  groupadd ncsadmin && groupadd ncsoper
  usermod -a -G ncsadmin $SSH_USERNAME
fi

# Save some space
/bin/rm -rf $INSTALL_DIR/{doc,man}

printf "==> Updating default shell skeletons\n"
echo "source $INSTALL_DIR/ncsrc" >> /etc/skel/.bashrc

# Catch the default user too (it's hard to get rid of that user as it's created already)
echo "source $INSTALL_DIR/ncsrc" >> /home/${SSH_USERNAME}/.bashrc

if [[ ! -z "$NSO_JAVA_OPTS" ]]; then
  if [[ $NSO_INSTALL_TYPE =~ local ]]; then
    echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> /etc/skel/.bashrc
    echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> /home/${SSH_USERNAME}/.bashrc
  else
    # This edit is somewhat fragile given the off chance the init script changes
    /usr/bin/sed -i -E "s/  export (.*)/  export \1 NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"/" /etc/init.d/ncs
  fi
fi

# Install any NEDs that may have been uploaded
nedList=()
shopt -s extglob nullglob
for f in $UPLOAD_DIR/ncs-*@(.tar.gz|.signed.bin)
do
  nedFile=`basename $f`
  if [[ $nedFile == *.signed.bin ]]; then
    tmpDir=`/usr/bin/mktemp -d $UPLOAD_DIR/nsoNED.XXXX`
    (cd $tmpDir; sh $f --skip-verification >> /dev/null)
    nedFile=`/usr/bin/basename $tmpDir/ncs-*.tar.gz`
    /bin/mv $tmpDir/$nedFile $UPLOAD_DIR
    /bin/rm -rf $tmpDir
  fi
  topLevelDir=`/usr/bin/tar -tzf $UPLOAD_DIR/$nedFile | /usr/bin/head -1`
  nedName=${topLevelDir%/}
  nedList+=($nedName)
  printf "==> Installing NED $nedName [$nedFile] to $nso_package_dir\n"
  /usr/bin/tar -xzf $UPLOAD_DIR/$nedFile --directory $nso_package_dir
done

# An MOTD to hint at what to do once folks log in
printf "==> Generating MOTD\n"
/bin/cat > /etc/motd <<EOF
#########
Cisco NSO $NSO_VER is installed in $INSTALL_DIR
#########

EOF

if [[ $NSO_INSTALL_TYPE =~ system ]]; then
  # Let them know about additional users for a system install
  /bin/cat >> /etc/motd <<EOF
The $SSH_USERNAME user has been added to the ncsadmin group. To add additional users to the
group, use the OS shell command:

    sudo usermod -a -G ncsadmin <username>

EOF
  elif [[ ${#nedList[@]} -gt 0 ]]; then
    # This was a local install and NEDs were supplied, so run an initial NSO setup for the default user.
    # Otherwise a system install will automatically load any NEDs in the package dir when NCS launches
    packageList=''
    for ned in "${nedList[@]}"
    do
      packageList="$packageList --package $nso_package_dir/$ned"
    done
    printf "==> Running initial ncs_setup to $RUN_DIR with ${#nedList[@]} package(s)\n"
    source $INSTALL_DIR/ncsrc
    $INSTALL_DIR/bin/ncs-setup --dest $RUN_DIR --use-copy $packageList
    /bin/chown -R ${SSH_USERNAME}:${SSH_USERNAME} $RUN_DIR
    /bin/cat >> /etc/motd <<EOF
Do 'ncs-setup --dest <local dir>' to get started with an initial configuration
or you could 'git clone' an existing NSO project repository.

EOF
     /bin/cat $RUN_DIR/README.ncs | /usr/bin/sed 1d >> /etc/motd
fi
exit 0

