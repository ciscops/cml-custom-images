#!/bin/bash

printf "==> Installing GitLab\n"

export DEBIAN_FRONTEND=noninteractive

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install GitLab
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash   
apt-get -qq -y install gitlab-ce

# Configure GitLab
# sed -i "s/^# letsencrypt\['enable'\].*/letsencrypt\['enable'\] = false/g" /etc/gitlab/gitlab.rb
sed -i "s/^# gitlab_rails\['initial_root_password'\].*/gitlab_rails\['initial_root_password'\] = \"$GITLAB_ROOT_PASSWORD\"/g" /etc/gitlab/gitlab.rb
sed -i "s/^# gitlab_rails\['initial_shared_runners_registration_token'\].*/gitlab_rails\['initial_shared_runners_registration_token'\] = \"$GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN\"/g" /etc/gitlab/gitlab.rb

# Install Runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
dpkg -i gitlab-runner_amd64.deb

# Create systemd service
mv /tmp/gitlab-config.sh /usr/local/sbin/gitlab-config.sh
mv /tmp/gitlab-config.service /etc/systemd/system/gitlab-config.service
# systemctl start gitlab-config
systemctl enable gitlab-config

# Install Runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
dpkg -i gitlab-runner_amd64.deb

# An MOTD to hint at what to do once folks log in
printf "==> Generating MOTD\n"
/bin/cat > /etc/motd <<EOF
###################
GitLab is installed
###################

EOF
exit 0
