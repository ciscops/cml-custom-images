#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

printf "==> Installing NSO software dependencies\n"
/bin/apt-get install -y -qq --no-install-recommends wget apt-utils openssh-client openjdk-${NSO_JAVA_VERSION}-jre-headless python3 tmux
if [[ ! -e /usr/bin/python ]]; then ln -s python3 /usr/bin/python ; fi

printf "==> Installing build tools for NSO packages\n"
/bin/apt-get install -y -qq --no-install-recommends sudo vim git make ant libxml2-utils xsltproc

if [[ -f $UPLOAD_DIR/requirements.txt ]]; then
  printf "==> Installing pip\n"
  /bin/apt-get install -y -qq --no-install-recommends python3-pip python3-venv
  pip3 install --no-cache --upgrade pip
  if [[ ! -e /usr/bin/pip ]]; then ln -s pip3 /usr/bin/pip ; fi

  printf "==> Creating venv and installing basic packages\n"
  python3 -m venv /venv
  . /venv/bin/activate
  pip3 install --no-cache setuptools wheel

  printf "==> Install packages from requirements\n"
  pip3 install --no-cache -r $UPLOAD_DIR/requirements.txt
fi

exit 0
