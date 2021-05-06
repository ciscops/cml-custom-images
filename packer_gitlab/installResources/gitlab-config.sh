#!/usr/bin/env bash

IPADDR=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
PASSWORD=$(sed -n "s/^gitlab_rails\['initial_root_password'\] = \"\(.*\)\"/\1/p" /etc/gitlab/gitlab.rb)
TOKEN=$(sed -n "s/^gitlab_rails\['initial_shared_runners_registration_token'\] = \"\(.*\)\"/\1/p" /etc/gitlab/gitlab.rb)

# If we have a password and an address, update the MOTD
if [[ ! -z $PASSWORD && ! -z $IPADDR ]]; then
/bin/cat > /etc/motd <<EOF
###################
GitLab is accessible at http://$IPADDR:8081 with credentials root/$PASSWORD
It can take up to five minutes for the GitLab UI to be available.
###################

EOF
fi

if [[ ! -z $IPADDR  ]]; then
# Update GitLab external_url with dynamic IP address and reconfigure
sed -i "s/^external_url.*/external_url \"http:\/\/$IPADDR:8081\"/g" /etc/gitlab/gitlab.rb
/usr/bin/gitlab-ctl reconfigure

# Register the runner
RUNNERS=$(gitlab-runner list 2>&1 | grep Token)
if [[ ! $RUNNERS && $TOKEN ]]; then
gitlab-runner register --non-interactive --url http://$IPADDR:8081 --registration-token "$TOKEN" --executor docker --docker-image python:2.7
fi
else
echo "Failed to obtain primary IP address"
exit 1
fi
