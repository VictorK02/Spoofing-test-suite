$TTL    604800
@       IN      SOA     ns1.myreceiver.com. admin.myreceiver.com. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.mysender.com.
@       IN      A       192.168.56.20
@       IN      MX      10 mail.myreceiver.com.
mail    IN      A       192.168.56.20