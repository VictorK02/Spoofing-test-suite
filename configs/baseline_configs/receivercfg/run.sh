#!/bin/bash

DOMAIN="myreceiver.com"

# Configs
sudo cp /configs/baseline_configs/receivercfg/main.cf /etc/postfix/main.cf

sudo postconf -e "mydestination = \$myhostname, $DOMAIN, localhost.com, localhost"

# Milter Chain
sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893"
sudo postconf -e "non_smtpd_milters = inet:localhost:8891, inet:localhost:8893"
sudo postconf -e "milter_default_action = reject"

# Configure OpenDKIM
sudo mkdir -p /run/opendkim
sudo chown opendkim:opendkim /run/opendkim

# Create the OpenDKIM override
sudo mkdir -p /etc/systemd/system/opendkim.service.d/
cat <<EOF | sudo tee /etc/systemd/system/opendkim.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/opendkim -P /run/opendkim/opendkim.pid -p inet:8891@localhost
RuntimeDirectory=opendkim
User=opendkim
Group=opendkim
EOF

# OpenDMARC Permissions & Systemd Override
sudo mkdir -p /run/opendmarc
sudo chown opendmarc:opendmarc /run/opendmarc

sudo mkdir -p /etc/systemd/system/opendmarc.service.d/
cat <<EOF | sudo tee /etc/systemd/system/opendmarc.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/opendmarc -p inet:8893@localhost -u opendmarc -P /run/opendmarc/opendmarc.pid
RuntimeDirectory=opendmarc
User=opendmarc
Group=opendmarc
EOF

sudo cp /configs/baseline_configs/receivercfg/opendkim.conf /etc/opendkim.conf
sudo cp /configs/baseline_configs/receivercfg/opendmarc.conf /etc/opendmarc.conf

# Force DNS to point to Sender VM
sudo rm -f /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 192.168.56.10
nameserver 8.8.8.8
EOF

# Ensure Mailbox Directory exists
sudo mkdir -p /var/mail
sudo chown root:mail /var/mail
sudo chmod 1777 /var/mail

# Dovecot: allow listening on all interfaces
sudo sed -i 's/^#\?listen =.*/listen = *, ::/' /etc/dovecot/dovecot.conf

# Dovecot: allow plaintext auth
sudo sed -i 's/^#\?disable_plaintext_auth =.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms =.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

cat <<EOF | sudo tee /etc/dovecot/conf.d/15-mail-namespace.conf
namespace inbox {
  type = private
  separator = /
  prefix = 
  location = mbox:~/mail:INBOX=/var/mail/%u
  inbox = yes
}
EOF

sudo sed -i 's/^mail_location/#mail_location/' /etc/dovecot/conf.d/10-mail.conf


# RSPAMD

echo "--- Applying Essential Rspamd Configuration ---"

cat <<EOF | sudo tee /etc/rspamd/local.d/redis.conf
servers = "127.0.0.1:6379";
timeout = 1s;
EOF

USER_PASSWORD="vagrant"
PASSWORD_HASH=$(rspamadm pw -p "$USER_PASSWORD")

cat <<EOF | sudo tee /etc/rspamd/local.d/worker-controller.inc
password = "$PASSWORD_HASH";
bind_socket = "*:11334"; # Vi tillåter bind på alla för att nå den från Kali
EOF

cat <<EOF | sudo tee /etc/rspamd/local.d/worker-proxy.inc
milter = yes;
timeout = 120s;
upstream "local" {
  default = yes;
  self_scan = yes;
}
EOF

echo "Running Rspamd config test..."
sudo rspamadm configtest

echo "--- Configuring Rspamd for DMARC Anomaly Detection ---"

sudo mkdir -p /etc/rspamd/local.d/
cat <<EOF | sudo tee /etc/rspamd/local.d/dmarc.conf
enabled = true;
ignore_hosts = ""; 
check_local = true;
EOF
cat <<EOF | sudo tee /etc/rspamd/local.d/spf.conf
check_local = true;
EOF
cat <<EOF | sudo tee /etc/rspamd/local.d/dkim.conf
check_local = true;
EOF

cat <<EOF | sudo tee /etc/rspamd/local.d/actions.conf
reject = 10.0;      
add_header = 1.0;    
no_action = 0.0;
EOF

cat <<EOF | sudo tee /etc/rspamd/local.d/force_actions.conf
rules {
    REJECT_DMARC_FAILURE {
        expression = "DMARC_POLICY_REJECT | DMARC_FAIL";
        action = "reject";
        message = "DMARC check failed - Anomaly detected";
    }
}
EOF

cat <<EOF | sudo tee /etc/rspamd/local.d/milter_headers.conf
extended_spam_headers = true;

use = ["x-spamd-result", "x-spam-level", "x-spam-status"];

skip_local = false;
authenticated_headers = ["x-spamd-result"];
EOF

sudo systemctl restart rspamd redis-server

echo "--- Rspamd Setup Complete ---"

sudo systemctl start rspamd redis-server
sudo systemctl enable rspamd redis-server

sudo systemctl daemon-reload
sudo systemctl restart postfix opendkim opendmarc dovecot

echo "Receiver Baseline Complete."