#!/bin/bash

echo "
### <=========================================================================================> ###
### ---> Replacing Domain MailAmigos.com = avex-trocadominio.sh ========> ###
### <=========================================================================================> ###
"

Data=`date +%d/%m/%Y-%T`
DominioAntigo=`hostname | cut -d. -f2-6`
ReversoAntigo=`cat /root/mailamigos-scripts/reverso.info`
UsuarioEnvio=`cat /root/mailamigos-scripts/usuarioenvio.info`
SenhaUsuarioEnvio=`cat /root/mailamigos-scripts/senhausuarioenvio.info`
SenhaUsuarioEnvioMysql=`echo -ne $SenhaUsuarioEnvio | base64`

echo "
This server is configured with the following domain : $DominioAntigo ...
What domain name would you like to replace $DominioAntigo ? "
read DominioNovo

echo "
This server is configured with the following reverseDNS: $ReversoAntigo ...
Which ReverseDNS do you want to replace $ReversoAntigo ? "
read ReversoNovo

echo "
This script can completely reset the server installation settings in this case
the database and Interspire will be completely replaced , you will lose the current data from the server ,
Are you sure you want to delete Interspire settings and database ? (yes | no) "
read RedefineIem

echo "
~> Fields of change in $Data : 
~> Domain $DominioAntigo changed too $DominioNovo
~> ReverseDNS $ReversoAntigo changed too $ReversoNovo
### <=========================================================================================> ###
" >> /root/mailamigos-scripts/Readme-2015.info

echo "
### ~> Setting please wait ... 
### <=========================================================================================> ###
"

if [ $RedefineIem = yes ]
then
	mv /var/www/avex/admin/includes/config.php . 
	mv /var/www/avex/fastimport/includes/conexao/conecta.php . 
	rm -rf /var/www/avex/*
	unzip -q /root/mailamigos-scripts/backup-local/.Originais/interspire-2015.zip -d /var/www/avex/
	mv config.php /var/www/avex/admin/includes/config.php
	mv conecta.php /var/www/avex/fastimport/includes/conexao/conecta.php
	mysql -uroot -p*v3434*i2802*p5348 -e "drop database avex;"
	mysql -uroot -p*v3434*i2802*p5348 -e "create database avex;"
	mysql -uroot -p*v3434*i2802*p5348 avex < /root/mailamigos-scripts/backup-local/.Originais/interspire-2015.sql
	mysql -uroot -p*v3434*i2802*p5348 avex < /root/mailamigos-scripts/backup-local/.Originais/email_banned_emails.sql
	chmod 777 /var/www/avex/admin/com/storage/ -R
	chmod 777 /var/www/avex/admin/addons/ -R
	chmod 777 /var/www/avex/admin/temp/ -R
	chmod 777 /var/www/avex/fastimport/ -R
	hmod 777 /var/www/avex/importacao/ -R
	chmod 777 /var/www/avex/admin/includes/config.php
fi

### ~> INFO

sed -i "s/$ReversoAntigo/$ReversoNovo/g" /root/mailamigos-scripts/reverso.info
sed -i "s/$DominioAntigo/$DominioNovo/g" /root/mailamigos-scripts/dominio.info
sed -i "s/$ReversoAntigo/$ReversoNovo/g" /root/mailamigos-scripts/Readme-2015.info
sed -i "s/$DominioAntigo/$DominioNovo/g" /root/mailamigos-scripts/Readme-2015.info

### ~> DNS

mv /var/named/chroot/var/named/$DominioAntigo.db /var/named/chroot/var/named/$DominioNovo.db
sed -i "s/$ReversoAntigo/$ReversoNovo/g" /var/named/chroot/var/named/$DominioNovo.db
sed -i "s/$DominioAntigo/$DominioNovo/g" /var/named/chroot/var/named/$DominioNovo.db
sed -i "s/$DominioAntigo/$DominioNovo/g" /var/named/chroot/etc/named.rfc1912.zones
sed -i '/DKIM/d' /var/named/chroot/var/named/$DominioNovo.db

/usr/sbin/opendkim-genkey -d $DominioNovo
cat default.txt >> /var/named/chroot/var/named/$DominioNovo.db
echo "" >> /var/named/chroot/var/named/$DominioNovo.db
rm -rf default.txt

service named restart

### ~> MYSQL

mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = 'return@$Dominio' WHERE area = 'BOUNCE_ADDRESS'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = 'localhost' WHERE area = 'BOUNCE_SERVER'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = 'return' WHERE area = 'BOUNCE_USERNAME'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = 'cmV0dXJuKnA1MzQ4KnZpcA==' WHERE area = 'BOUNCE_PASSWORD'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = 'localhost' WHERE area = 'SMTP_SERVER'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = '$UsuarioEnvio' WHERE area = 'SMTP_USERNAME'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = '$SenhaUsuarioEnvioMysql' WHERE area = 'SMTP_PASSWORD'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = '587' WHERE area = 'SMTP_PORT'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = '/novalidate-cert' WHERE area = 'BOUNCE_EXTRASETTINGS'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_config_settings SET areavalue = '$UsuarioEnvio@$Dominio' WHERE area = 'EMAIL_ADDRESS'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_users SET emailaddress = '$UsuarioEnvio@$Dominio' WHERE userid = '1'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "UPDATE email_users SET adminnotify_email = '$UsuarioEnvio@$Dominio' WHERE userid = '1'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "update email_usergroups set limit_hourlyemailsrate = '0' where groupname = 'System Admin'; commit; flush privileges;"
mysql -uroot -p*v3434*i2802*p5348 avex -e "update email_config_settings set areavalue = '0' where area = 'MAXHOURLYRATE'; commit; flush privileges;"

service mysqld restart

### ~> APACHE

mv /etc/httpd/conf.d/$DominioAntigo.conf /etc/httpd/conf.d/$DominioNovo.conf
sed -i "s/$DominioAntigo/$DominioNovo/g" /var/www/index.html
sed -i "s/$DominioAntigo/$DominioNovo/g" /home/$UsuarioEnvio/websites/index.html
sed -i "s/$DominioAntigo/$DominioNovo/g" /var/www/avex/admin/includes/config.php
sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/httpd/conf.d/$DominioNovo.conf
sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/httpd/conf/httpd.conf
sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/squirrelmail/config.php
rm -rf /var/log/httpd/$DominioAntigo*

service httpd restart

### ~> DOVECOT

sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/dovecot.conf

service dovecot restart

### ~> POSTFIX

sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/postfix/main.cf

service postfix restart

### ~> PMTA

sed -i "s/$ReversoAntigo/$ReversoNovo/g" /etc/pmta/config
sed -i "s/$DominioAntigo/$DominioNovo/g" /etc/pmta/config
mv default.private /etc/pmta/$DominioNovo-dkim.key
chown pmta:pmta /etc/pmta/ -R

service pmta restart

### ~> BACKUP

ls /root/mailamigos-scripts/hostftp.info

if [ $? = 0 ]
then

HostFtp=`cat /root/mailamigos-scripts/hostftp.info`
UsuarioFtp=`cat /root/mailamigos-scripts/usuarioftp.info`
SenhaUsuarioFtp=`cat /root/mailamigos-scripts/senhausuarioftp.info`

/usr/bin/ftp -in << EOF
open $HostFtp
user $UsuarioFtp $SenhaUsuarioFtp
bin
mkdir backup-$Dominio
bye
EOF

fi

echo "
### ---> Please note your new sending domain data ... 
### <=========================================================================================> ###
"
cat /var/named/chroot/var/named/$DominioNovo.db

echo "
### ---> Synchronizing data , wiping installation, wait ...
### <=========================================================================================> ###
" 
/usr/sbin/ntpdate -u pool.ntp.br >> /dev/null 2>&1 || /usr/bin/rdate -s rdate.cpanel.net >> /dev/null 2>&1
echo server.$DominioNovo > /proc/sys/kernel/hostname
hostname server.$DominioNovo
updatedb

echo "
### ---> Restarting Server ...
### <=========================================================================================> ###
" 

shutdown -r now





