If you have lost your postfixadmin main account password, you can generate a new one like this :

Get salted-hash :
```
docker exec -ti mailserver doveadm pw -s SHA512-CRYPT -p YOUR_NEW_PASSWORD
```

And edit database :
```
docker exec -it mariadb bash

# mysql -u root -p

MariaDB [(none)]> use postfix;
MariaDB [(none)]> UPDATE admin SET password = '{SHA512-CRYPT}HASH' WHERE username = 'admin@domain.tld';

Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

MariaDB [(none)]> quit

exit
```