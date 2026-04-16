#!/bin/bash

DOMAIN="myreceiver.com"

# 2. Configs
sudo cp /configs/baseline_configs/receivercfg/main.cf /etc/postfix/main.cf

# --- FIX: Ensure Postfix knows it owns the domain (prevents loops) ---
sudo postconf -e "mydestination = \$myhostname, $DOMAIN, localhost.com, localhost"

# --- FIX: Milter Chain ---
sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893"
sudo postconf -e "non_smtpd_milters = inet:localhost:8891, inet:localhost:8893"
sudo postconf -e "milter_default_action = reject"

# 3. Configure OpenDKIM (Systemd Override + Config)
# Ensure the runtime directory exists
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

# 3.5 OpenDMARC Permissions & Systemd Override
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

# 4. Force DNS to point to Sender VM
sudo rm -f /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 192.168.56.10
nameserver 8.8.8.8
EOF

# --- FIX: Ensure Mailbox Directory exists ---
sudo mkdir -p /var/mail
sudo chown root:mail /var/mail
sudo chmod 1777 /var/mail

# Dovecot: allow listening on all interfaces
sudo sed -i 's/^#\?listen =.*/listen = *, ::/' /etc/dovecot/dovecot.conf

# Dovecot: allow plaintext auth for lab use
sudo sed -i 's/^#\?disable_plaintext_auth =.*/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#\?auth_mechanisms =.*/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf

# 5. Restart
sudo systemctl daemon-reload
sudo systemctl restart opendkim opendmarc postfix

echo "Receiver Baseline Complete."