#!/bin/bash

### <=================================================================================================> ###
### ---> monitoramento = Versão 2018 [carlos@mdc-homestation ~]$ Seg Fev 23 07:22:47 BRT =============> ###
 
### <=================================================================================================> ###

MonLog=/tmp/monitoramento.log
Data=`date`
Domain=`cat /root/mailamigos-scripts/domain.info` 
MonitoringEmail=`cat /root/mailamigos-scripts/monitoringemail.info`


/bin/sync && /bin/echo 3 > /proc/sys/vm/drop_caches >> /dev/null 2>&1

echo "
### <=================================================================================================> ###
Monitoramento do server.$Domain em $Data : 
### <=================================================================================================> ###
" > $MonLog

/etc/init.d/mysqld status >> $MonLog
	if [ $? -ne 0 ]
	then
		/etc/init.d/mysqld restart >> $MonLog
		sleep 30
		/etc/init.d/mysqld status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then 
		 		echo "Error == Mysql down " >> $MonLog
		 	else
		 		echo "Error == Mysql restart " >> $MonLog
		 	fi
	fi

/etc/init.d/httpd status >> $MonLog
	if [ $? -ne 0  ]
	then
		/etc/init.d/httpd restart >> $MonLog
		sleep 30
		/etc/init.d/httpd status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then 
		 		echo "Error == Apache down  " >> $MonLog
		 	else
		 		echo "Error == Apache restart " >> $MonLog
		 	fi
	fi

/etc/init.d/dovecot status  >> $MonLog
	if [ $? -ne 0  ]
	then
		/etc/init.d/dovecot restart >> $MonLog
		sleep 30
		/etc/init.d/dovecot status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then
		 		echo "Error == Dovecot down  " >> $MonLog
		 	else
		 		echo "Error == Dovecot restart " >> $MonLog
		 	fi
	fi

/etc/init.d/postfix status >> $MonLog
	if [ $? -ne 0  ]
	then
		/etc/init.d/postfix restart >> $MonLog
		sleep 30
		/etc/init.d/postfix status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then 
		 		echo "Error == Postfix down  " >> $MonLog
		 	else
		 		echo "Error == Postfix restart " >> $MonLog
		 	fi
	fi

/etc/init.d/named status >> $MonLog
	if [ $? -ne 0  ]
	then
		/etc/init.d/named restart >> $MonLog
		sleep 30
		/etc/init.d/named status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then 
		 		echo "Error == Named down  " >> $MonLog
		 	else
		 		echo "Error == Named restart " >> $MonLog
		 	fi
	fi

/etc/init.d/pmta status >> $MonLog
	if [ $? -ne 0  ]
	then
		/etc/init.d/pmta restart >> $MonLog
		sleep 120
		/etc/init.d/pmta status >> $MonLog
		 	if [ $? -ne 0 ]
		 	then 
		 		echo "Error == PowerMTA down " >> $MonLog
		 	else
		 		echo "Error == PowerMTA restart " >> $MonLog
		 	fi
	fi

/sbin/service pmtahttp status >> $MonLog
   if [ $? = 0  ]
   then
		/usr/bin/w | grep root >> $MonLog
			if [ $? -ne 0 ]
			then 
				/sbin/service pmtahttp stop >> $MonLog
	            echo "Error == PMTA-http ended " >> $MonLog
	        fi
    fi

/sbin/service squid status >> $MonLog
   if [ $? = 0  ]
   then
		/usr/bin/w | grep root >> $MonLog
			if [ $? -ne 0 ]
			then 
				/sbin/service squid stop >> $MonLog
	            echo "Errorr == PMTA-http ended " >> $MonLog
	        fi
    fi
    
df -h | grep VolGroup >> /dev/null 2>&1
	if [ $? -ne 0 ]
	then 
		UsoHD=`df -h / |grep %\ / |awk '{print $5}' |sed 's/%//'`
	else 
    	UsoHD=`df -h / |grep %\ / |awk '{print $4}' |sed 's/%//'`
    fi

	if [ $UsoHD -gt 85 ]
	then
		echo "Error = HD in $Data is at $UsoHD% usage, trying to free up space: " >> $MonLog
		rm -rf /backup-local-$Domain
		/usr/bin/find /root/mailamigos-scripts/backup-local/ -type f -mtime +2 -exec rm -rf {} \+ 
		/usr/bin/find /var/log/pmta/ -type f -mtime +2 -exec rm -rf {} \+ 
		/usr/bin/find /var/spool/pmta/ -type f -mtime +2 -exec rm -rf {} \+ 
		> /var/named/chroot/var/named/data/named.run
		chown named:named /var/named/chroot/var/named/data/named.run
		/etc/init.d/named restart >> $MonLog
		sleep 30
	fi

grep Error $MonLog >> /dev/null 2>&1
	if [ $? -ne 0 ]
	then	
		echo "
### --->  Server Ok ! ( Ok )
### <=================================================================================================> ###
" >> $MonLog
	else
		echo "
### --->  Failure Server ! ( Error )
### <=================================================================================================> ###
" >> $MonLog

		cat $MonLog >> /var/log/pmta/log
		cat $MonLog >> /var/log/messages
		
		Versao=`cut -d" " -f3 /etc/redhat-release | cut -d"." -f1`
			if [ $Versao = 6 ]
			then
				cat $MonLog | mail -r manutencao@server.$Domain -s "Monitoring the server. $Domain == Server with problems in $Data !" $MonitoringEmail
			else
				cat $MonLog | mail -s "Monitoring the server. $Domain == Server in trouble in $Data!" $MonitoringEmail -- -f manutencao@server.$Domain
			fi
	fi
