#!/bin/bash

apt update
DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils bind9 opendkim opendkim-tools opendmarc swaks net-tools dovecot-imapd

postconf -e "myhostname = mail.myreceiver.com"
postconf -e "mydomain = myreceiver.com"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = all"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
postconf -e "mynetworks = 127.0.0.0/8 192.168.56.0/24"

systemctl restart postfix

source /configs/baseline_configs/receivercfg/run.sh