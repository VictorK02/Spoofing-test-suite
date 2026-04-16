$TTL 604800
@   IN  SOA mail.mysender.com. admin.mysender.com. (
        2026031101 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

@       IN  NS      mail.mysender.com.
@       IN  A       192.168.56.10
mail    IN  A       192.168.56.10
@       IN  MX  10  mail.mysender.com.
@       IN  TXT     "v=spf1 ip4:192.168.56.10 -all"
_dmarc IN TXT "v=DMARC1; p=reject; adkim=r; aspf=r"