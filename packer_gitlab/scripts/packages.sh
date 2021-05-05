#!/bin/bash

printf "==> Installing package dependencies\n"

export DEBIAN_FRONTEND=noninteractive

printf "==> Installing required packages\n"
/bin/apt-get install -y -qq --no-install-recommends curl openssh-server ca-certificates tzdata perl

exit 0
