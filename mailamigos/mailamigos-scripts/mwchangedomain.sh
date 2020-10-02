#!/bin/bash

echo "
### <=========================================================================================> ###
### ---> Replacing Domain Mailwizz www.MailAmigos.com = avex-trocaDomain.sh ========> ###
### <=========================================================================================> ###
"

Data=`date +%d/%m/%Y-%T`
DomainAntigo=`hostname | cut -d. -f2-6`
ReverseDNSAntigo=`cat /root/mailamigos-scripts/reversedns.info`
SendingUser=`cat /root/mailamigos-scripts/sendinguser.info`
SendingUserPass=`cat /root/mailamigos-scripts/sendinguserpass.info`
SendingUserPassMysql=`echo -ne $SendingUserPass | base64`
sqlpass=`cat /root/mailamigos-scripts/sqlpass.info`
adminemail=`cat /root/mailamigos-scripts/adminemail.info`
firstname=`cat /root/mailamigos-scripts/firstname.info`
lastname=`cat /root/mailamigos-scripts/lastname.info`

echo "
This server is configured with the following domain : $DomainAntigo ...
What domain name would you like to replace $DomainAntigo ? "
read DomainNovo

echo "
This server is configured with the following reverseDNS: $ReverseDNSAntigo ...
If you would like to change your current reverseDNS $ReverseDNSAntigo please type it in "
read ReverseDNSNovo

echo "
This script can completely reset the server installation settings in this case
the database and Mailwizz will be completely replaced , you will lose the current data from the server ,
Are you sure you want to delete Mailwizz settings and database ? (yes | no) "
read RedefineMW

echo "
~> Fields of change in $Data : 
~> Domain $DomainAntigo changed too $DomainNovo
~> ReverseDNS $ReverseDNSAntigo changed too $ReverseDNSNovo
### <=========================================================================================> ###
" >> /root/mailamigos-scripts/Readme.info

echo "
### ~> Setting please wait ... 
### <=========================================================================================> ###
"

if [ $RedefineMW = yes ]
then
	rm -rf /var/www/mw/apps/common/config/main-custom.php 
	rm -rf /var/www/mw/*
	unzip -q /root/mailamigos-scripts/backup-local/.Originais/mailwizz.zip -d /var/www/mw/
	rm -rf main-custom.php /var/www/mw/apps/common/config/main-custom.php
	mysql -uroot -p$sqlpass -e "drop database mailwizz;"
	mysql -uroot -p$sqlpass -e "create database mailwizz;"
	mysql -uroot -p$sqlpass mailwizz < /root/mailamigos-scripts/backup-local/.Originais/mailwizz.sql
	mysql -uroot -p$sqlpass mailwizz < /root/mailamigos-scripts/backup-local/.Originais/mw_email_blacklist.sql
chmod 777 /var/www/mw/apps/common/config
chmod 777 /var/www/mw/apps/common/runtime
chmod 777 /var/www/mw/backend/assets/cache
chmod 777 /var/www/mw/customer/assets/cache
chmod 777 /var/www/mw/frontend/assets/cache
chmod 777 /var/www/mw/frontend/assets/files
chmod 777 /var/www/mw/frontend/assets/gallery
chmod 777 /var/www/mw/apps/extensions

echo "<?php defined('MW_PATH') || exit('No direct script access allowed');

    
return array(

    // application components
    'components' => array(
        'db' => array(
            'connectionString'  => 'mysql:host=localhost;dbname=mailwizz',
            'username'          => 'root',
            'password'          => '$sqlpass',
            'tablePrefix'       => 'mw_',
        ),
    ),
);
" > /var/www/mw/apps/common/config/main-custom.php

fi

### ~> INFO

sed -i "s/$ReverseDNSAntigo/$ReverseDNSNovo/g" /root/mailamigos-scripts/reversedns.info
sed -i "s/$DomainAntigo/$DomainNovo/g" /root/mailamigos-scripts/domain.info
sed -i "s/$ReverseDNSAntigo/$ReverseDNSNovo/g" /root/mailamigos-scripts/Readme.info
sed -i "s/$DomainAntigo/$DomainNovo/g" /root/mailamigos-scripts/Readme.info
sed -i "s/admin@$DomainAntigo/admin@$DomainNovo/g" /root/mailamigos-scripts/adminemail.info

### ~> DNS

mv /var/named/chroot/var/named/$DomainAntigo.db /var/named/chroot/var/named/$DomainNovo.db
sed -i "s/$ReverseDNSAntigo/$ReverseDNSNovo/g" /var/named/chroot/var/named/$DomainNovo.db
sed -i "s/$DomainAntigo/$DomainNovo/g" /var/named/chroot/var/named/$DomainNovo.db
sed -i "s/$DomainAntigo/$DomainNovo/g" /var/named/chroot/etc/named.rfc1912.zones
sed -i '/DKIM/d' /var/named/chroot/var/named/$DomainNovo.db

/usr/sbin/opendkim-genkey -d $DomainNovo
cat default.txt >> /var/named/chroot/var/named/$DomainNovo.db
echo "" >> /var/named/chroot/var/named/$DomainNovo.db
rm -rf default.txt

service named restart

### ~> MYSQL

mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_bounce_server SET hostname = '$Domain';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_bounce_server SET email = 'return@$Domain';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET hostname = '$Domain';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET username = '$SendingUser';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET password = '$SendingUserPass';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET from_email = '$SendingUser@$Domain';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET from_name = '$SendingUser';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET reply_to_email = '$MonitoringEmail';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET port = '2525';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_delivery_server SET status = 'active';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_customer SET first_name = '$firstname';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_customer SET last_name = '$lastname';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_customer SET email = '$adminemail';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_user SET first_name = '$firstname';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_user SET last_name = '$lastname';"
mysql -uroot -p$sqlpass mailwizz -e "UPDATE mw_user SET email = '$adminemail';"

service mysqld restart

### ~> APACHE

mv /etc/httpd/conf.d/$DomainAntigo.conf /etc/httpd/conf.d/$DomainNovo.conf
sed -i "s/$DomainAntigo/$DomainNovo/g" /var/www/index.html
sed -i "s/$DomainAntigo/$DomainNovo/g" /home/$SendingUser/websites/index.html
sed -i "s/$DomainAntigo/$DomainNovo/g" /var/www/avex/admin/includes/config.php
sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/httpd/conf.d/$DomainNovo.conf
sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/httpd/conf/httpd.conf
sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/squirrelmail/config.php
rm -rf /var/log/httpd/$DomainAntigo*

service httpd restart

### ~> DOVECOT

sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/dovecot.conf

service dovecot restart

### ~> POSTFIX

sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/postfix/main.cf

service postfix restart

### ~> PMTA

sed -i "s/$ReverseDNSAntigo/$ReverseDNSNovo/g" /etc/pmta/config
sed -i "s/$DomainAntigo/$DomainNovo/g" /etc/pmta/config
mv default.private /etc/pmta/$DomainNovo-dkim.key
chown pmta:pmta /etc/pmta/ -R

service pmta restart

### ~> BACKUP

ls /root/mailamigos-scripts/hostftp.info

if [ $? = 0 ]
then

HostFtp=`cat /root/mailamigos-scripts/hostftp.info`
UserFtp=`cat /root/mailamigos-scripts/userftp.info`
UserPassFtp=`cat /root/mailamigos-scripts/userpassftp.info`

/usr/bin/ftp -in << EOF
open $HostFtp
user $UserFtp $UserPassFtp
bin
mkdir backup-$Domain
bye
EOF

fi

echo "
### ---> ...THIS IS YOUR NEW DNS INFORMATION PLEASE REPLACE YOUR OLD DNS INFORMATION IN THE README FILE WITH THIS...
### <=========================================================================================> ###
"
cat /var/named/chroot/var/named/$DomainNovo.db

echo "
### ---> Synchronizing data , wiping installation, wait ...
### <=========================================================================================> ###
" 
/usr/sbin/ntpdate -u pool.ntp.br >> /dev/null 2>&1 || /usr/bin/rdate -s rdate.cpanel.net >> /dev/null 2>&1
echo server.$DomainNovo > /proc/sys/kernel/hostname
hostname server.$DomainNovo
updatedb

echo "
### ---> Restarting Server ...
### <=========================================================================================> ###
" 

shutdown -r now





