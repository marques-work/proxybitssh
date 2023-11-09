#!/bin/bash
# vim: sts=2 sw=2 et ai

set -euo pipefail

# ensure tunnel .ssh folder exists
mkdir -p /home/tunnel/.ssh
chmod 700 /home/tunnel/.ssh

# ensure tunnel .ssh/authorized_keys exists
touch /home/tunnel/.ssh/authorized_keys
chmod 600 /home/tunnel/.ssh/authorized_keys

if [ -n "$(ls -A /etc/ssh/keys-pub/*)" ]; then
  # add all public keys to authorized_keys
  cat /etc/ssh/keys-pub/* >> /home/tunnel/.ssh/authorized_keys
fi

# ensure sshd and httpd are running
sudo service ssh restart
sudo service apache2 restart

# show running services
sudo service --status-all

# keep container running
tail -f /dev/null
