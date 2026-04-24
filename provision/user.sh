#!/bin/bash

apt update
DEBIAN_FRONTEND=noninteractive apt install -y swaks netcat-openbsd thunderbird

echo "--- Installing SSH Tools on Kali ---"

# ssh
mkdir -p /home/vagrant/.ssh
cat <<EOF > /home/vagrant/.ssh/config
Host sender
    HostName 192.168.56.10
    User vagrant
    StrictHostKeyChecking no

Host receiver
    HostName 192.168.56.20
    User vagrant
    StrictHostKeyChecking no
EOF

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
sudo chmod 600 /home/vagrant/.ssh/config

cat <<EOF | sudo tee -a /etc/hosts
192.168.56.20  mail.myreceiver.com myreceiver.com receiver
EOF