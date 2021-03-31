#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing NSO software dependencies"
/bin/apt-get install -y -qq --no-install-recommends wget apt-utils openssh-client default-jre-headless python3 tmux
if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi

echo "==> Installing build tools for NSO packages"
/bin/apt-get install -y -qq --no-install-recommends sudo vim git make ant libxml2-utils xsltproc

echo "==> Installing pip"
/bin/apt-get install -y -qq --no-install-recommends python3-pip python3-venv
pip3 install --no-cache --upgrade pip
if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

echo "==> Creating venv and installing basic packages"
python3 -m venv /venv
. /venv/bin/activate
pip3 install --no-cache setuptools wheel

echo "==> Install packages from requirements"
#wget -q ${HTTP_URL}/requirements.txt -O /tmp/requirements.txt
pip3 install --no-cache -r /tmp/requirements.txt
