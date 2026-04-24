$TTL    604800
@       IN      SOA     ns1.company.com. admin.company.com. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.company.com.
@       IN      A       192.168.56.10
@       IN      MX  10  mail.company.com.
ns1     IN      A       192.168.56.10
mail    IN      A       192.168.56.10

; --- SPF Record ---
; Only allows the Sender VM IP to send mail for company.com
@       IN      TXT     "v=spf1 ip4:192.168.56.100 -all"

; --- DMARC Record ---
; p=reject tells the receiver to drop the mail if SPF/DKIM alignment fails
_dmarc  IN      TXT     "v=DMARC1; p=reject; adkim=s; aspf=s; rua=mailto:admin@company.com"