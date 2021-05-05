#!/usr/bin/env bash

ipaddr=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

if [ $ipaddr ]; then
sed -i "s/^external_url.*/external_url \"https:\/\/$ipaddr\"/g" /etc/gitlab/gitlab.rb
sed -i "s/^# letsencrypt\['enable'\].*/letsencrypt\['enable'\] = false/g" /etc/gitlab/gitlab.rb
/usr/bin/gitlab-ctl reconfigure
else
echo "Failed to obtain primary IP address"
fi