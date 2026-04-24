#!/bin/bash

DOMAIN="myreceiver.com"

# 2. Configs
sudo cp /configs/baseline_configs/receivercfg/main.cf /etc/postfix/main.cf

sudo postconf -e "mydestination = \$myhostname, $DOMAIN, localhost.com, localhost"

# --- Milter Chain ---
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

# Konfigurera Redis (Krävs för statistik och historik)
# Vi ser till att Rspamd vet var Redis finns
cat <<EOF | sudo tee /etc/rspamd/local.d/redis.conf
servers = "127.0.0.1:6379";
timeout = 1s;
EOF

# Generera lösenord för WebUI (Lösenord: vagrant)
# Vi använder rspamadm för att skapa en hash direkt i skriptet
USER_PASSWORD="vagrant"
PASSWORD_HASH=$(rspamadm pw -p "$USER_PASSWORD")

# Konfigurera Worker Controller (WebUI access)
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

# Validera konfigurationen
# Detta är det sista steget i guiden för att se att allt är korrekt syntaxmässigt
echo "Running Rspamd config test..."
sudo rspamadm configtest

echo "--- Configuring Rspamd for DMARC Anomaly Detection ---"

# Aktivera DMARC-modulen och tvinga kontroller
# Vi ser till att den inte hoppar över lokala nätverk (eftersom vi kör i lab)
sudo mkdir -p /etc/rspamd/local.d/
cat <<EOF | sudo tee /etc/rspamd/local.d/dmarc.conf
# Utför DMARC-koll även om SPF/DKIM verkar saknas
enabled = true;
# Viktigt: Tillåt kollar från privata IP-adresser (Vagrant-nätet)
ignore_hosts = ""; 
EOF

# Skapa regler för att upptäcka "The Gap" (Syntaxfel & Multiple From)
# Dessa symboler finns i Rspamd, men vi ger dem höga poäng här.
cat <<EOF | sudo tee /etc/rspamd/local.d/groups.conf
symbols {
    "MULTIPLE_FROM" {
        weight = 7.0;
        description = "Multiple From headers (Potential Exploit)";
    }
    "FROM_INVALID" {
        weight = 5.0;
        description = "Invalid From header syntax";
    }
    "FORGED_SENDER" {
        weight = 4.0;
        description = "Envelope and header sender addresses do not match";
    }
}
EOF

# Konfigurera Actions (När ska den bounca mailet?)
# Vi vill att den ska vara känslig för DMARC-strul.
cat <<EOF | sudo tee /etc/rspamd/local.d/actions.conf
reject = 10.0;       # Släng mailet om poängen når 10
add_header = 1.0;    # Lägg till 'X-Spam' header i Thunderbird vid 1 poäng
no_action = 0.0;
EOF

# Tvinga Reject vid DMARC-fel (även vid p=none om vi vill)
# Detta täpper till gapet där DMARC annars bara loggar.
cat <<EOF | sudo tee /etc/rspamd/local.d/force_actions.conf
rules {
    REJECT_DMARC_FAILURE {
        expression = "DMARC_POLICY_REJECT | DMARC_FAIL";
        action = "reject";
        message = "DMARC check failed - Anomaly detected";
    }
}
EOF

# make it add the results in the mail headers
cat <<EOF | sudo tee /etc/rspamd/local.d/milter_headers.conf
# Lägg till en utförlig rapport i mailets headers
extended_spam_headers = true;

# Definiera vilka headers som ska läggas till
use = ["x-spamd-result", "x-spam-level", "x-spam-status"];

# Vi vill se detta även om mailet INTE klassas som spam (för debugging)
skip_local = false;
authenticated_headers = ["x-spamd-result"];
EOF

# Starta om Rspamd
sudo systemctl restart rspamd redis-server

echo "--- Rspamd Setup Complete ---"


# Start and enable services
sudo systemctl start rspamd redis-server
sudo systemctl enable rspamd redis-server

##################################################

# Restart
sudo systemctl daemon-reload
sudo systemctl restart postfix opendkim opendmarc dovecot

echo "Receiver Baseline Complete."