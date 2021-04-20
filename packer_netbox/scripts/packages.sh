#!/bin/bash

printf "==> Installing package dependencies\n"

export DEBIAN_FRONTEND=noninteractive

printf "==> Installing utilities, Python\n"
/bin/apt-get install -y -qq --no-install-recommends git wget apt-utils openssh-client python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi

printf "==> Installing postgres db\n"
/bin/apt-get install -y -qq --no-install-recommends sudo postgresql libpq-dev

printf "==> Installing redis\n"
/bin/apt-get install -y -qq --no-install-recommends redis-server

printf "==> Installing nginx\n"
/bin/apt-get install -y -qq --no-install-recommends nginx

exit 0
