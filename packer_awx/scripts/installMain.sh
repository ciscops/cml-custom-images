#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# K3s defaults to containerd as a CRI, but Docker can be laid on top
docker_opt=""
#container_pull_cmd="ctr image pull"
if [[ $K3S_USE_DOCKER =~ true ]]; then
  printf "==> Installing Docker as K3s CRI\n"
  curl -sSL https://releases.rancher.com/install-docker/19.03.sh | sh
  usermod -aG docker $SSH_USERNAME
  docker_opt="--docker"
fi

printf "==> Installing K3s $K3S_VER\n"

# Install and enable for next boot
export INSTALL_K3S_VERSION=v${K3S_VER}+k3s1
export INSTALL_K3S_SKIP_START=true
export K3S_KUBECONFIG_MODE="644"
curl -sfL https://get.k3s.io | sh -s - server $docker_opt

# TODO Given the K3S_KUBECONFIG_MODE setting above, is the setup of a user ~/.kube/config necessary?

printf "==> Updating default shell skeletons\n"
cat <<'EOF' | sudo tee -a /etc/skel/.bashrc > /dev/null
if [[ ! -d ~/.kube && -f /etc/rancher/k3s/k3s.yaml ]]; then
    mkdir ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER:`id -g` ~/.kube/config
fi
alias k="kubectl"
alias kd="kubectl describe"
alias kg="kubectl get"
alias kgw="kubectl get -o wide"
EOF

# Catch the default user too (it's hard to get rid of that user as it's created already)
cat <<'EOF' | sudo tee -a /home/${SSH_USERNAME}/.bashrc > /dev/null
if [[ ! -d ~/.kube && -f /etc/rancher/k3s/k3s.yaml ]]; then
    mkdir ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER:`id -g` ~/.kube/config
fi
alias k="kubectl"
alias kd="kubectl describe"
alias kg="kubectl get"
alias kgw="kubectl get -o wide"
EOF

# An MOTD to hint at what to do once folks log in
printf "==> Generating MOTD\n"
/bin/cat > /etc/motd <<EOF
################
AWX instructions
################

Run the following script to finish the AWX install and launch:
$AWX_RESOURCE_DIR/startup.sh

EOF

# Prepare for instance boot
mkdir -p $AWX_RESOURCE_DIR
curl -sSL https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml > $AWX_RESOURCE_DIR/awx-operator.yaml
cp $UPLOAD_DIR/awx.yaml $AWX_RESOURCE_DIR/
cp $UPLOAD_DIR/startup.sh $AWX_RESOURCE_DIR/
chmod 755 $AWX_RESOURCE_DIR/startup.sh

# If not using Docker, then bail out here. We can't pre-pull the containers because
# containerd isn't running yet. The images will be fetched when an instance is booted.

[[ $K3S_USE_DOCKER =~ true ]] || exit 0

# At this point Docker is the CRI, so try pre-populating the container image cache
defaultsFile=`mktemp -p /tmp awxXXXX`
curl -sSL https://raw.githubusercontent.com/ansible/awx-operator/devel/roles/installer/defaults/main.yml > $defaultsFile

# TODO Pulling the awx-operator manifest & installer defaults is risky for getting out of sync with this container list

printf "==> Priming the local CRI container image cache\n"
container_pull_cmd="docker image pull -q"

# This should handle surrounding double quotes if present
function getImageName () {
  grep "$1" $2 | sed -E 's/.*image: "?([^"]+)"?/\1/'
}

# K3s
IFS=' ' read -r -a k3_image_list <<< "$K3S_IMAGES"
if [[ ${#k3_image_list[@]} -gt 0 ]]; then
  for image in "${k3_image_list[@]}"
  do
    $container_pull_cmd $image
  done
fi

# AWX
$container_pull_cmd `getImageName 'tower_redis_image' $defaultsFile`
$container_pull_cmd `getImageName 'tower_postgres_image' $defaultsFile`
$container_pull_cmd `getImageName 'quay.io/ansible/awx-ee' $defaultsFile`
$container_pull_cmd `getImageName 'tower_image: ' $defaultsFile`
$container_pull_cmd `getImageName 'quay.io/ansible/awx-operator' $AWX_RESOURCE_DIR/awx-operator.yaml`

# The awx-operator image should be in the local cache
sed -i 's/imagePullPolicy: "Always"/imagePullPolicy: "Never"/' $AWX_RESOURCE_DIR/awx-operator.yaml

# TODO Set up automatic launch of AWX startup script at instance boot

exit 0
