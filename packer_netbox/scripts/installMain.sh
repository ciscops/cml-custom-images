#!/bin/bash

printf "==> Installing Netbox\n"

#sudo -u postgres psql
#CREATE DATABASE netbox;
#CREATE USER netbox WITH PASSWORD ${NETBOX_DB_PASSWORD};
#GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
#\q

sudo -u postgres psql postgres -c "CREATE DATABASE netbox;"
sudo -u postgres psql postgres -c "CREATE USER netbox WITH PASSWORD '${NETBOX_DB_PASSWORD}';"
sudo -u postgres psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"

mkdir -p /opt/netbox/ && cd /opt/netbox/
git clone -b master https://github.com/netbox-community/netbox.git .
adduser --system --group netbox
chown --recursive netbox /opt/netbox/netbox/media/
cd /opt/netbox/netbox/netbox/
cp configuration.example.py configuration.py
sed -i --follow-symlinks "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/g" /opt/netbox/netbox/netbox/configuration.py
sed -i --follow-symlinks "s/'USER': ''/'USER': 'netbox'/g" /opt/netbox/netbox/netbox/configuration.py
sed -i --follow-symlinks "s/'PASSWORD': ''/'PASSWORD': '${NETBOX_DB_PASSWORD}'/g" /opt/netbox/netbox/netbox/configuration.py
OUTPUT=`python3 ../generate_secret_key.py`
sed -i --follow-symlinks "s/SECRET_KEY = ''/SECRET_KEY = '$OUTPUT'/g" /opt/netbox/netbox/netbox/configuration.py

/opt/netbox/upgrade.sh
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py createsuperuser --noinput
cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl start netbox netbox-rq
systemctl enable netbox netbox-rq

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-subj "/C=US/ST=VA/L=Herndon/O=Dis/CN=www.example.com" \
-keyout /etc/ssl/private/netbox.key \
-out /etc/ssl/certs/netbox.crt

cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
systemctl restart nginx

# An MOTD to hint at what to do once folks log in
printf "==> Generating MOTD\n"
/bin/cat > /etc/motd <<EOF
###################
Netbox is installed
###################

Netbox credentials are admin/admin.

EOF
exit 0
