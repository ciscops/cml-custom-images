#!/bin/bash

printf "==> Installing GitLab\n"

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install GitLab
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash   
sudo EXTERNAL_URL="http://gitlab.example.com" apt-get install gitlab-ce

# Install Runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
sudo dpkg -i gitlab-runner_amd64.deb

# Create systemd service
sudo mv /tmp/gitlab-config.sh /usr/local/sbin/gitlab-config.sh
sudo mv /tmp/gitlab-config.service /etc/systemd/system/gitlab-config.service
# systemctl start gitlab-config
systemctl enable gitlab-config

# Install Runner
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb"
sudo dpkg -i gitlab-runner_amd64.deb

# An MOTD to hint at what to do once folks log in
printf "==> Generating MOTD\n"
/bin/cat > /etc/motd <<EOF
###################
GitLab is installed
###################

EOF
exit 0
