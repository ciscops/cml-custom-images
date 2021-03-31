#!/bin/bash -x

echo "==> Installing NSO $NSO_VER to $INSTALL_DIR"

#wget -q ${HTTP_URL}/nso-${NSO_VER}.linux.x86_64.installer.bin -O /tmp/nso-${NSO_VER}.linux.x86_64.installer.bin

/bin/mkdir -p $INSTALL_DIR
/bin/sh /tmp/nso-${NSO_VER}.linux.x86_64.installer.bin $INSTALL_DIR --local-install

# Normally these keys should be RW only for user, but may need R potentially random user
/bin/chmod 0644 ${INSTALL_DIR}/netsim/confd/etc/confd/ssh/ssh_host_rsa_key
/bin/chmod 0644 ${INSTALL_DIR}/etc/ncs/ssh/ssh_host_ed25519_key


# Save some space
/bin/rm -rf ${INSTALL_DIR}/{doc,man}

# Install NEDs
/bin/tar -zxvf /tmp/${NED_IOS}.tar.gz --directory ${INSTALL_DIR}/packages/neds
/bin/tar -zxvf /tmp/${NED_XR}.tar.gz --directory ${INSTALL_DIR}/packages/neds
/bin/tar -zxvf /tmp/${NED_NX}.tar.gz --directory ${INSTALL_DIR}/packages/neds
/bin/tar -zxvf /tmp/${NED_ASA}.tar.gz --directory ${INSTALL_DIR}/packages/neds

# Create NSO instance
source ${INSTALL_DIR}/ncsrc
${INSTALL_DIR}/bin/ncs-setup --package ${INSTALL_DIR}/packages/neds/${NED_IOS_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_XR_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_NX_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_ASA_ID} \
 --dest /home/ubuntu/nso-instance

# Change ownership to ubuntu
/bin/sudo chown -Rv ubuntu:ubuntu /home/ubuntu/nso-instance

echo "==> Updating default shell skeletons"
echo "source ${INSTALL_DIR}/ncsrc" >> /etc/skel/.bashrc
echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> /etc/skel/.bashrc

# Catch the default user too (it's hard to get rid of that user as it's created already)
echo "source ${INSTALL_DIR}/ncsrc" >> ~ubuntu/.bashrc
echo "export NCS_JAVA_VM_OPTIONS=\"${NSO_JAVA_OPTS}\"" >> ~ubuntu/.bashrc


# An MOTD to hint at what to do once folks log in
echo "==> Generating MOTD"
/bin/cat > /etc/motd <<EOF
#####################
Cisco NSO ${NSO_VER} is locally installed in ${INSTALL_DIR}
#####################

The below command has already been executed:
${INSTALL_DIR}/bin/ncs-setup --package ${INSTALL_DIR}/packages/neds/${NED_IOS_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_XR_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_NX_ID} \
 --package ${INSTALL_DIR}/packages/neds/${NED_ASA_ID} \
 --dest /home/ubuntu/nso-instance

To run your nso instance:
/home/ubuntu/nso-instance/ncs

NSO  login is admin/admin

EOF
