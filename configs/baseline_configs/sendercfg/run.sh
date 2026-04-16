#!/bin/bash
DOMAIN="mysender.com"

# 2. Setup Directories
sudo mkdir -p /etc/opendkim/keys/$DOMAIN
sudo chown -R opendkim:opendkim /etc/opendkim

# 3. Handle DKIM Keys (Don't overwrite existing ones)
if [ ! -f "/etc/opendkim/keys/$DOMAIN/default.private" ]; then
    sudo opendkim-genkey -s default -d $DOMAIN -D /etc/opendkim/keys/$DOMAIN
    sudo chown opendkim:opendkim /etc/opendkim/keys/$DOMAIN/default.private
fi

# 3.5 some DKIM stuff (Systemd Override)
sudo mkdir -p /etc/systemd/system/opendkim.service.d/

cat <<EOF | sudo tee /etc/systemd/system/opendkim.service.d/override.conf
[Service]
ExecStart=
# Use 127.0.0.1 instead of localhost
ExecStart=/usr/sbin/opendkim -P /run/opendkim/opendkim.pid -p inet:8891@127.0.0.1
RuntimeDirectory=opendkim
User=opendkim
Group=opendkim
EOF

sudo mkdir -p /run/opendkim
sudo chown opendkim:opendkim /run/opendkim

# 4. Generate Tables (Overwrite with clean baseline)
echo "127.0.0.1" | sudo tee /etc/opendkim/trusted.hosts
echo "192.168.56.0/24" | sudo tee -a /etc/opendkim/trusted.hosts
echo "localhost" | sudo tee -a /etc/opendkim/trusted.hosts
echo "mail.mysender.com" | sudo tee -a /etc/opendkim/trusted.hosts
echo "*@$DOMAIN default._domainkey.$DOMAIN" | sudo tee /etc/opendkim/signing.table
echo "default._domainkey.$DOMAIN $DOMAIN:default:/etc/opendkim/keys/$DOMAIN/default.private" | sudo tee /etc/opendkim/key.table

# 5. Build Zone File (Template + Key)
sudo cp /configs/baseline_configs/sendercfg/bind/db.$DOMAIN /etc/bind/db.$DOMAIN
sudo cp /configs/baseline_configs/sendercfg/bind/db.myreceiver.com /etc/bind/db.myreceiver.com

# 1. Strip the file down to just the Base64 string
# We remove newlines, tabs, spaces, parentheses, quotes, and the label/comment
FULL_STRING=$(grep -v '^;' /etc/opendkim/keys/$DOMAIN/default.txt | tr -d '\n\t "()')

# 2. Now extract only the part after 'p='
CLEAN_KEY=$(echo "$FULL_STRING" | sed 's/.*p=//; s/;.*//')

# 3. Split into two chunks for BIND (ensure PART2 gets the rest)
PART1=$(echo "$CLEAN_KEY" | cut -c 1-220)
PART2=$(echo "$CLEAN_KEY" | cut -c 221-)

# 4. Write to BIND
echo "" | sudo tee -a /etc/bind/db.$DOMAIN
cat <<EOF | sudo tee -a /etc/bind/db.$DOMAIN
default._domainkey IN TXT ( "v=DKIM1; h=sha256; k=rsa; p=$PART1"
                            "$PART2" )
EOF

# 6. Apply System Configs
sudo cp /configs/baseline_configs/sendercfg/main.cf /etc/postfix/main.cf
sudo cp /configs/baseline_configs/sendercfg/opendkim.conf /etc/opendkim.conf
sudo cp /configs/baseline_configs/sendercfg/bind/named.conf.local /etc/bind/
sudo cp /configs/baseline_configs/sendercfg/bind/named.conf.options /etc/bind/

sudo rm -f /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf
nameserver 127.0.0.1
nameserver 8.8.8.8
EOF

# 8. Restart
sudo systemctl daemon-reload
sudo systemctl restart bind9
sudo systemctl restart postfix opendkim

echo "Sender Baseline Complete."