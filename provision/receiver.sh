#!/bin/bash

apt update
DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils bind9 opendkim opendkim-tools opendmarc swaks net-tools dovecot-imapd ccze rspamd redis

postconf -e "myhostname = mail.myreceiver.com"
postconf -e "mydomain = myreceiver.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = all"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
postconf -e "mynetworks = 127.0.0.0/8 192.168.56.0/24"

sudo cp /configs/setconfig.sh /usr/local/bin/setconfig
sudo chmod +x /usr/local/bin/setconfig

systemctl restart postfix dovecot

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

echo "export PS1='\[\e[1;31m\][RECEIVER]\[\e[0m\]:\w\$ '" >> /home/vagrant/.bashrc

source /configs/baseline_configs/receivercfg/run.sh