#!/bin/bash

### <==========================================================================================> ###
### backup-ftp = Versão 2018 $ Qua Jan 28 13:08:14 BRST =============> ###

### <==========================================================================================> ###

Domain=`cat /root/mailamigos-scripts/domain.info`
MonitoringEmail=`cat /root/mailamigos-scripts/monitoringemail.info`
Data=`date`
DataPers=`date +%Y_%m_%d`
BackupFtpLog="/tmp/backup-ftp.log"
Arquivo=`ls /root/mailamigos-scripts/backup-local | tail -1`
HostFtp=`cat /root/mailamigos-scripts/hostftp.info`
UserFtp=`cat /root/mailamigos-scripts/userftp.info`
UserPassFtp=`cat /root/mailamigos-scripts/userpassftp.info`

echo "
### <=========================================================================================> ###
### ---> Backup domain $Domain in $Data!
### <=========================================================================================> ###
" > $BackupFtpLog 

cd /root/mailamigos-scripts/backup-local/

echo " Performing backup ...
Always check in $HostFtp the space available and the consistency of backups. 
### <=========================================================================================> ###
" >> $BackupFtpLog 

/usr/bin/wput -B $Arquivo ftp://$UserFtp:$UserPassFtp@$HostFtp/backup-$Domain/ >> $BackupFtpLog

echo "
Backup the server. $Domain made in $DataPers! 
### <=========================================================================================> ###

###---> IMPORTANT INFORMATION: 
###---> the server. $Domain keeps the last 7 daily backups! 
###---> Target server does not erase backups for safety!
###---> Always check the space available and the consistency of backups.

### <=========================================================================================> ###
" >> $BackupFtpLog 

cat $BackupFtpLog >> /var/log/pmta/log
cat $BackupFtpLog >> /var/log/messages

Versao=`cut -d" " -f3 /etc/redhat-release | cut -d"." -f1`
	if [ $Versao = 6 ]
	then
		cat $BackupFtpLog | mail -r manutencao@server.$Domain -s "Backup the server. $Domain in $Data" $MonitoringEmail
	else
		cat $BackupFtpLog | mail -s "Backup the server. $Domain in $Data" $MonitoringEmail -- -f manutencao@server.$Domain
	fi
