#!/bin/bash

echo "==> Installing NSO $NSO_VER to $INSTALL_DIR"

/bin/mkdir -p $INSTALL_DIR

nsoInstallerSigned=nso-${NSO_VER}.linux.x86_64.signed.bin
nsoInstaller=nso-${NSO_VER}.linux.x86_64.installer.bin

# If using the signed wrapper, unpack the inner installer first
if [[ -f $UPLOAD_DIR/$nsoInstallerSigned ]]; then
  tmpDir=`/usr/bin/mktemp -d $UPLOAD_DIR/nsoInstall.XXXX`
  (cd $tmpDir; sh $UPLOAD_DIR/$nsoInstallerSigned --skip-verification >> /dev/null)
  /bin/mv $tmpDir/$nsoInstaller $UPLOAD_DIR
  /bin/rm -rf $tmpDir $UPLOAD_DIR/$nsoInstallerSigned
fi
/bin/sh $UPLOAD_DIR/$nsoInstaller $INSTALL_DIR --local-install

# Normally these keys should be RW only for user, but may need R for potentially random user
/bin/chmod 0644 $INSTALL_DIR/netsim/confd/etc/confd/ssh/ssh_host_rsa_key
/bin/chmod 0644 $INSTALL_DIR/etc/ncs/ssh/ssh_host_ed25519_key

# Save some space
/bin/rm -rf $INSTALL_DIR/{doc,man}

echo "==> Updating default shell skeletons"
echo "source $INSTALL_DIR/ncsrc" >> /etc/skel/.bashrc
echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> /etc/skel/.bashrc

# Catch the default user too (it's hard to get rid of that user as it's created already)
echo "source $INSTALL_DIR/ncsrc" >> ~ubuntu/.bashrc
echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> ~ubuntu/.bashrc

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
  echo "==> Installing NED $nedName [$nedFile] to $INSTALL_DIR/packages/neds"
  /usr/bin/tar -xzf $UPLOAD_DIR/$nedFile --directory $INSTALL_DIR/packages/neds
done

# An MOTD to hint at what to do once folks log in
echo "==> Generating MOTD"
/bin/cat > /etc/motd <<EOF
#########
Cisco NSO $NSO_VER is installed in $INSTALL_DIR
#########

Do 'ncs-setup --dest <local dir>' to get started with an initial configuration
or you could 'git clone' an existing NSO project repository.

EOF

# If NEDs were installed, then run an initial NSO setup for the default user
if [[ ${#nedList[@]} -gt 0 ]]; then
  packageList=''
  for ned in "${nedList[@]}"
  do
    packageList="$packageList --package $INSTALL_DIR/packages/neds/$ned"
  done
  echo "==> Running initial ncs_setup to $RUN_DIR with ${#nedList[@]} package(s)"
  source $INSTALL_DIR/ncsrc
  $INSTALL_DIR/bin/ncs-setup --dest $RUN_DIR $packageList
  /bin/chown -R ubuntu:ubuntu $RUN_DIR
  /bin/cat $RUN_DIR/README.ncs | /usr/bin/sed 1d >> /etc/motd
fi
