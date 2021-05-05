#!/usr/bin/env bash

ipaddr=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

if [ $ipaddr ]; then
sed -i "s/^external_url.*/external_url \"http:\/\/$ipaddr:8081\"/g" /etc/gitlab/gitlab.rb
sed -i "s/^# letsencrypt\['enable'\].*/letsencrypt\['enable'\] = false/g" /etc/gitlab/gitlab.rb
/usr/bin/gitlab-ctl reconfigure
gitlab-runner register --non-interactive --url http://$ipaddr:8081 registration-token zkguBxeyBzsEioz-KzKb --executor docker --docker-image python:2.7
else
echo "Failed to obtain primary IP address"
fi