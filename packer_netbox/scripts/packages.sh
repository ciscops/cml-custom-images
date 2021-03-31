#!/bin/bash

echo "==> Installing package dependencies"

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing utilities, Python"
/bin/apt-get install -y -qq --no-install-recommends git wget apt-utils openssh-client python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi

echo "==> Installing postgres db"
/bin/apt-get install -y -qq --no-install-recommends sudo postgresql libpq-dev

echo "==> Installing redis"
/bin/apt-get install -y -qq --no-install-recommends redis-server

echo "==> Installing nginx"
/bin/apt-get install -y -qq --no-install-recommends nginx
