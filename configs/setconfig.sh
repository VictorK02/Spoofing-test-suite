#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Usage: setconfig [default|strictdmarc|rspamd]"
    exit 1
fi

case "$1" in
    default)
        echo "Switching to DEFAULT configuration..."
        sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893"
        sudo postconf -e "non_smtpd_milters = inet:localhost:8891, inet:localhost:8893"
        sudo postconf -e "milter_default_action = reject"
        sudo sed -i '/^RejectMultiValueFrom/d' /etc/opendmarc.conf
        sudo sed -i '/^RequiredHeaders/d' /etc/opendmarc.conf
        sudo systemctl start opendkim opendmarc
        sudo systemctl restart postfix opendmarc
        ;;
    strict)
        echo "Switching to STRICT DMARC configuration..."
        sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893"
        sudo postconf -e "non_smtpd_milters = inet:localhost:8891, inet:localhost:8893"
        sudo postconf -e "milter_default_action = reject"
        sudo sed -i '/^RejectMultiValueFrom/d' /etc/opendmarc.conf
        sudo sed -i '/^RequiredHeaders/d' /etc/opendmarc.conf
        echo "RejectMultiValueFrom true" | sudo tee -a /etc/opendmarc.conf
        echo "RequiredHeaders true" | sudo tee -a /etc/opendmarc.conf
        sudo systemctl start opendkim opendmarc
        sudo systemctl restart postfix opendmarc
        ;;
    rspamd)
        echo "Switching to RSPAMD configuration..."
        sudo postconf -e "smtpd_milters = inet:localhost:11332"
        sudo postconf -e "non_smtpd_milters = inet:localhost:11332"
        sudo postconf -e "milter_default_action = accept"
        sudo systemctl stop opendkim opendmarc
        sudo systemctl restart postfix
        ;;
    *)
        echo "Invalid option: $1"
        echo "Valid options are: default, strict, rspamd"
        exit 1
        ;;
esac

echo "Configuration '$1' applied successfully."