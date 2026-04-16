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

source /configs/baseline_configs/sendercfg/run.sh