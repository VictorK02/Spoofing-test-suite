#!/bin/bash

apt update
DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils bind9 opendkim opendkim-tools opendmarc swaks net-tools

postconf -e "myhostname = mail.mysender.com"
postconf -e "mydomain = mysender.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = all"
postconf -e "mydestination ="
postconf -e "mynetworks = 127.0.0.0/8 192.168.56.0/24"

systemctl restart postfix

# ssh
echo "--- Configuring SSH for Password Access ---"

echo "vagrant:vagrant" | sudo chpasswd
sudo rm -f /etc/ssh/sshd_config.d/*.conf

cat <<EOF | sudo tee /etc/ssh/sshd_config
Include /etc/ssh/sshd_config.d/*.conf
PasswordAuthentication yes
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

sudo systemctl restart ssh

echo "export PS1='\[\e[1;31m\][SENDER]\[\e[0m\]:\w\$ '" >> /home/vagrant/.bashrc

source /configs/baseline_configs/sendercfg/run.sh