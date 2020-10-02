#!/bin/bash

### <=================================================================================================> ###
### ---> maintenance = 2018 Version $ Wed Jan 28 13:08:14 am BRST ===============> ###
### 
### <=================================================================================================> ###

/usr/sbin/ntpdate -u pool.ntp.br >> /dev/null 2>&1 || /usr/bin/rdate -s rdate.cpanel.net >> /dev/null 2>&1
/usr/bin/updatedb 

Domain=`cat /root/mailamigos-scripts/domain.info` 
SendingUser=`cat /root/mailamigos-scripts/sendinguser.info`
MonitoringEmail=`cat /root/mailamigos-scripts/monitoringemail.info`
Data=`date`
ManData=`date +%Y_%m_%d`
ManLog="/tmp/manutencao-diaria.log"
ArqBackup="backup-local-$Domain-$ManData.tar.gz"
IpAddr=`cat /root/mailamigos-scripts/ips.info`
ListaRbl=`cat /root/mailamigos-scripts/rbl-2015.info`
sqlpass=`cat /root/mailamigos-scripts/sqlpass.info`

echo "
### <=================================================================================================> ###
Maintenance of the server. $Domain in $Data ...
### <=================================================================================================> ###
" > $ManLog

echo " 
Analysis Ips ...
### <=================================================================================================> ###
" >> $ManLog

for Ip in $IpAddr
do
    echo -n "$Ip = ">> $ManLog
    Teste1=`host $Ip 200.221.11.100 | tail -1 | awk '{ print $5 }'`
    Teste2=`host $Teste1 200.221.11.100 | tail -1 | awk '{ print $4 }'`
        if [ "$Ip" = "$Teste2" ]
        then
            host $Ip 200.221.11.100 | tail -1 | grep $Domain >> /dev/null 2>&1
                if [ $? = 0 ]
                then 
                    echo -n "$Teste1 OK = ">> $ManLog
                else
                    echo -n "Check Reverse $Teste1 = " >> $ManLog
                fi
        else 
            echo -n "Check Reverse $Teste1 = " >> $ManLog
        fi

    Octeto1=`echo "$Ip" | cut -f1 -d"."`
    Octeto2=`echo "$Ip" | cut -f2 -d"."`
    Octeto3=`echo "$Ip" | cut -f3 -d"."`
    Octeto4=`echo "$Ip" | cut -f4 -d"."`

    IpReverseDNS=`echo "$Octeto4.$Octeto3.$Octeto2.$Octeto1"`
    QualidadeIp=`dig $IpReverseDNS.score.senderscore.com @200.221.11.100 | grep ";; ANSWER" -A1 | grep senderscore | cut -d'.' -f11`
    
    ls /root/mailamigos-scripts/ipspeed.info >> /dev/null 2>&1 
    if [ $? = 0 ]
    then
        VelocidadeIp=`cat /root/mailamigos-scripts/ipspeed.info`
        grep -o " $Ip " /etc/pmta/config >> /dev/null 2>&1 
        if [ $? = 0 ]
        then
            LinhaVelocidadeIp=$(expr $(grep -n " $Ip " /etc/pmta/config | cut -d: -f1) + 3) 
            sed -i "$LinhaVelocidadeIp s/.*/max-msg-rate $VelocidadeIp\/h/" /etc/pmta/config 
            echo "Quality configured ip $VelocidadeIp/h in $QualidadeIp% ! " >> $ManLog
        else
            echo "Ip of quality $QualidadeIp% ! " >> $ManLog
        fi
    else
        MaximumIPSpeed=`cat /root/mailamigos-scripts/maximumipspeed.info`
        CalculoVelocidade=`expr $MaximumIPSpeed \* \( $QualidadeIp + 1 \) / 100 2> /dev/null`
        [ $CalculoVelocidade -lt 250 ] && VelocidadeVariavel=250 || VelocidadeVariavel=$CalculoVelocidade
        grep -o " $Ip " /etc/pmta/config >> /dev/null 2>&1 
        if [ $? = 0 ]
        then
            LinhaVelocidadeIp=$(expr $(grep -n " $Ip " /etc/pmta/config | cut -d: -f1) + 3) 
            sed -i "$LinhaVelocidadeIp s/.*/max-msg-rate $VelocidadeVariavel\/h/" /etc/pmta/config 
            echo "Quality of the configured ip $VelocidadeVariavel/h in $QualidadeIp% ! " >> $ManLog
        else
            echo "Quality configured ip in $QualidadeIp% ! " >> $ManLog
        fi
    fi

    for BlackList in $ListaRbl
    do 
        dig $IpReverseDNS.$BlackList @200.221.11.100 |grep ";; ANSWER" >> /dev/null 2>&1
        if [ $? = 0 ]
        then
            dig $IpReverseDNS.$BlackList @200.221.11.100 |grep ";; ANSWER" -A1 |grep "spamhaus" |grep "127.0.1.255" >> /dev/null 2>&1
            if [ $? = 1 ]
            then
                echo "Listed on $BlackList" >> $ManLog
            fi
        fi
    done

    grep $Ip /var/log/pmta/*`date +%Y-%m-%d`*.csv | grep -q 'Cloudmark Poor Reputation Sender Blacklist'
        if [ $? = 0 ] 
        then 
            echo "Listed on CSI-Cloudmark" >> $ManLog
        fi

    grep $Ip /var/log/pmta/*`date +%Y-%m-%d`*.csv | grep -q 'Trend Micro Network Reputation Service' 
        if [ $? = 0 ] 
        then 
            echo "Listed on Trend Micro" >> $ManLog
        fi

echo " 
### <=================================================================================================> ###
" >> $ManLog

done

VelocidadeMaximaInterspire=`grep max-msg-rate /etc/pmta/config | grep -v '#' | cut -d' ' -f2 | cut -d/ -f1 | paste -s -d + | bc`
/usr/bin/mysql -uroot -p$sqlpass avex -e "update email_usergroups set limit_hourlyemailsrate = '$VelocidadeMaximaInterspire' where groupname = 'System Admin'; commit; flush privileges;"
/usr/bin/mysql -uroot -p$sqlpass avex -e "update email_config_settings set areavalue = '$VelocidadeMaximaInterspire' where area = 'MAXHOURLYRATE'; commit; flush privileges;"
VelocidadeMaximaPmta=`expr $VelocidadeMaximaInterspire \* 2`
LinhaVelocidadeMaximaPmta=$(grep -n 'Limite de envios do Powermta' /etc/pmta/config | cut -d: -f1) 
sed -i "$LinhaVelocidadeMaximaPmta s/.*/max-msg-rate $VelocidadeMaximaPmta\/h # Limite de envios do Powermta/" /etc/pmta/config

echo "
The maximum speed was set at server $VelocidadeMaximaInterspire emails per hour
### <=================================================================================================> ###
" >> $ManLog


echo "stopping services ... 
### <=================================================================================================> ###
" >> $ManLog

/etc/init.d/crond stop >> /dev/null 2>&1 && /etc/init.d/crond stop >> /dev/null 2>&1
/etc/init.d/pmta stop >> /dev/null 2>&1; sleep 120 && /etc/init.d/pmta stop >> /dev/null 2>&1
/etc/init.d/named stop >> /dev/null 2>&1; sleep 60 && /etc/init.d/named stop >> /dev/null 2>&1
/etc/init.d/postfix stop >> /dev/null 2>&1; sleep 30 && /etc/init.d/postfix stop >> /dev/null 2>&1
/etc/init.d/httpd stop >> /dev/null 2>&1; sleep 15 && /etc/init.d/httpd stop >> /dev/null 2>&1
/etc/init.d/dovecot stop >> /dev/null 2>&1 && /etc/init.d/dovecot stop >> /dev/null 2>&1

echo "Starting process of cleaning and checking of folders and Logs ... 
### <=================================================================================================> ###
" >> $ManLog

rm -rf /backup-local-$Domain
/usr/bin/find /root/mailamigos-scripts/backup-local/ -type f -mtime +7 -exec rm -rf {} \+ 
/usr/bin/find /var/log/pmta/ -type f -mtime +7 -exec rm -rf {} \+ 
/usr/bin/find /var/spool/pmta/ -type f -mtime +7 -exec rm -rf {} \+ 
> /var/named/chroot/var/named/data/named.run
chown named:named /var/named/chroot/var/named/data/named.run

echo "Maintenance of the mysql ... 
### <=================================================================================================> ###
" >> $ManLog

/usr/bin/mysql -uroot -p$sqlpass avex -e "TRUNCATE email_list_subscriber_events;"

/usr/bin/mysql -uroot -p$sqlpass avex -e "DELETE email_list_subscribers FROM email_list_subscribers INNER JOIN email_banned_emails ON email_list_subscribers.emailaddress=email_banned_emails.emailaddress WHERE email_list_subscribers.emailaddress=email_banned_emails.emailaddress"

/usr/bin/mysql -uroot -p$sqlpass avex -e "DELETE FROM email_list_subscribers WHERE domainname LIKE '%.de' 
OR domainname LIKE '%.googlegroups.com'
OR domainname LIKE '%.yahoogroups.com'
OR domainname LIKE '%.googlegroups.com.br'
OR domainname LIKE '%.yahoogroups.com.br'
OR domainname LIKE '%.gov.br'
OR domainname LIKE '%.jus.br'
OR domainname LIKE '%.leg.br'
OR domainname LIKE '%.mil.br'
OR domainname LIKE '%.adv.br'
OR domainname LIKE '%.mp.br'
OR domainname LIKE '%.biz'
OR domainname LIKE '%.ph'
OR domainname LIKE '%.ac'
OR domainname LIKE '%.ad'
OR domainname LIKE '%.ae'
OR domainname LIKE '%.af'
OR domainname LIKE '%.ag'
OR domainname LIKE '%.ai'
OR domainname LIKE '%.al'
OR domainname LIKE '%.am'
OR domainname LIKE '%.an'
OR domainname LIKE '%.ao'
OR domainname LIKE '%.aq'
OR domainname LIKE '%.ar'
OR domainname LIKE '%.as'
OR domainname LIKE '%.at'
OR domainname LIKE '%.au'
OR domainname LIKE '%.aw'
OR domainname LIKE '%.az'
OR domainname LIKE '%.ba'
OR domainname LIKE '%.bb'
OR domainname LIKE '%.bd'
OR domainname LIKE '%.be'
OR domainname LIKE '%.bf'
OR domainname LIKE '%.bg'
OR domainname LIKE '%.bh'
OR domainname LIKE '%.bi'
OR domainname LIKE '%.bj'
OR domainname LIKE '%.bm'
OR domainname LIKE '%.bn'
OR domainname LIKE '%.bo'
OR domainname LIKE '%.bs'
OR domainname LIKE '%.bt'
OR domainname LIKE '%.bv'
OR domainname LIKE '%.bw'
OR domainname LIKE '%.by'
OR domainname LIKE '%.bz'
OR domainname LIKE '%.ca'
OR domainname LIKE '%.cc'
OR domainname LIKE '%.cd'
OR domainname LIKE '%.cf'
OR domainname LIKE '%.cg'
OR domainname LIKE '%.ch'
OR domainname LIKE '%.ci'
OR domainname LIKE '%.ck'
OR domainname LIKE '%.cl'
OR domainname LIKE '%.cm'
OR domainname LIKE '%.cn'
OR domainname LIKE '%.co'
OR domainname LIKE '%.cr'
OR domainname LIKE '%.cu'
OR domainname LIKE '%.cv'
OR domainname LIKE '%.cx'
OR domainname LIKE '%.cy'
OR domainname LIKE '%.cz'
OR domainname LIKE '%.dj'
OR domainname LIKE '%.dk'
OR domainname LIKE '%.dm'
OR domainname LIKE '%.do'
OR domainname LIKE '%.dz'
OR domainname LIKE '%.ec'
OR domainname LIKE '%.ee'
OR domainname LIKE '%.eg'
OR domainname LIKE '%.er'
OR domainname LIKE '%.es'
OR domainname LIKE '%.et'
OR domainname LIKE '%.eu'
OR domainname LIKE '%.fi'
OR domainname LIKE '%.fj'
OR domainname LIKE '%.fk'
OR domainname LIKE '%.fm'
OR domainname LIKE '%.fo'
OR domainname LIKE '%.fr'
OR domainname LIKE '%.ga'
OR domainname LIKE '%.gb'
OR domainname LIKE '%.gd'
OR domainname LIKE '%.ge'
OR domainname LIKE '%.gf'
OR domainname LIKE '%.gg'
OR domainname LIKE '%.gh'
OR domainname LIKE '%.gi'
OR domainname LIKE '%.gl'
OR domainname LIKE '%.gm'
OR domainname LIKE '%.gn'
OR domainname LIKE '%.gp'
OR domainname LIKE '%.gq'
OR domainname LIKE '%.gr'
OR domainname LIKE '%.gs'
OR domainname LIKE '%.gt'
OR domainname LIKE '%.gu'
OR domainname LIKE '%.gw'
OR domainname LIKE '%.hk'
OR domainname LIKE '%.hm'
OR domainname LIKE '%.hn'
OR domainname LIKE '%.hr'
OR domainname LIKE '%.ht'
OR domainname LIKE '%.hu'
OR domainname LIKE '%.id'
OR domainname LIKE '%.ie'
OR domainname LIKE '%.il'
OR domainname LIKE '%.im'
OR domainname LIKE '%.in'
OR domainname LIKE '%.io'
OR domainname LIKE '%.iq'
OR domainname LIKE '%.ir'
OR domainname LIKE '%.is'
OR domainname LIKE '%.it'
OR domainname LIKE '%.je'
OR domainname LIKE '%.jm'
OR domainname LIKE '%.jo'
OR domainname LIKE '%.jp'
OR domainname LIKE '%.ke'
OR domainname LIKE '%.kg'
OR domainname LIKE '%.kh'
OR domainname LIKE '%.ki'
OR domainname LIKE '%.km'
OR domainname LIKE '%.kn'
OR domainname LIKE '%.kr'
OR domainname LIKE '%.kw'
OR domainname LIKE '%.ky'
OR domainname LIKE '%.kz'
OR domainname LIKE '%.la'
OR domainname LIKE '%.lb'
OR domainname LIKE '%.lc'
OR domainname LIKE '%.li'
OR domainname LIKE '%.lk'
OR domainname LIKE '%.lr'
OR domainname LIKE '%.ls'
OR domainname LIKE '%.lt'
OR domainname LIKE '%.lu'
OR domainname LIKE '%.lv'
OR domainname LIKE '%.ly'
OR domainname LIKE '%.ma'
OR domainname LIKE '%.mc'
OR domainname LIKE '%.md'
OR domainname LIKE '%.me'
OR domainname LIKE '%.mg'
OR domainname LIKE '%.mh'
OR domainname LIKE '%.ml'
OR domainname LIKE '%.mm'
OR domainname LIKE '%.mn'
OR domainname LIKE '%.mo'
OR domainname LIKE '%.mp'
OR domainname LIKE '%.mq'
OR domainname LIKE '%.mr'
OR domainname LIKE '%.ms'
OR domainname LIKE '%.mt'
OR domainname LIKE '%.mu'
OR domainname LIKE '%.mv'
OR domainname LIKE '%.mw'
OR domainname LIKE '%.mx'
OR domainname LIKE '%.my'
OR domainname LIKE '%.mz'
OR domainname LIKE '%.nb'
OR domainname LIKE '%.nc'
OR domainname LIKE '%.ne'
OR domainname LIKE '%.nf'
OR domainname LIKE '%.ng'
OR domainname LIKE '%.ni'
OR domainname LIKE '%.nl'
OR domainname LIKE '%.no'
OR domainname LIKE '%.np'
OR domainname LIKE '%.nr'
OR domainname LIKE '%.nu'
OR domainname LIKE '%.nz'
OR domainname LIKE '%.om'
OR domainname LIKE '%.pa'
OR domainname LIKE '%.pe'
OR domainname LIKE '%.pf'
OR domainname LIKE '%.pg'
OR domainname LIKE '%.pk'
OR domainname LIKE '%.pl'
OR domainname LIKE '%.pm'
OR domainname LIKE '%.pn'
OR domainname LIKE '%.pr'
OR domainname LIKE '%.ps'
OR domainname LIKE '%.pt'
OR domainname LIKE '%.pw'
OR domainname LIKE '%.py'
OR domainname LIKE '%.qa'
OR domainname LIKE '%.re'
OR domainname LIKE '%.ro'
OR domainname LIKE '%.ru'
OR domainname LIKE '%.rw'
OR domainname LIKE '%.sa'
OR domainname LIKE '%.sb'
OR domainname LIKE '%.sc'
OR domainname LIKE '%.sd'
OR domainname LIKE '%.se'
OR domainname LIKE '%.sg'
OR domainname LIKE '%.sh'
OR domainname LIKE '%.si'
OR domainname LIKE '%.sj'
OR domainname LIKE '%.sk'
OR domainname LIKE '%.sl'
OR domainname LIKE '%.sm'
OR domainname LIKE '%.sn'
OR domainname LIKE '%.so'
OR domainname LIKE '%.sr'
OR domainname LIKE '%.ss'
OR domainname LIKE '%.st'
OR domainname LIKE '%.su'
OR domainname LIKE '%.sv'
OR domainname LIKE '%.sy'
OR domainname LIKE '%.sz'
OR domainname LIKE '%.tc'
OR domainname LIKE '%.td'
OR domainname LIKE '%.tf'
OR domainname LIKE '%.tg'
OR domainname LIKE '%.th'
OR domainname LIKE '%.tj'
OR domainname LIKE '%.tk'
OR domainname LIKE '%.tl'
OR domainname LIKE '%.tm'
OR domainname LIKE '%.to'
OR domainname LIKE '%.tr'
OR domainname LIKE '%.tt'
OR domainname LIKE '%.tv'
OR domainname LIKE '%.tw'
OR domainname LIKE '%.tz'
OR domainname LIKE '%.ua'
OR domainname LIKE '%.ug'
OR domainname LIKE '%.uk'
OR domainname LIKE '%.um'
OR domainname LIKE '%.us'
OR domainname LIKE '%.uy'
OR domainname LIKE '%.uz'
OR domainname LIKE '%.va'
OR domainname LIKE '%.vc'
OR domainname LIKE '%.ve'
OR domainname LIKE '%.vg'
OR domainname LIKE '%.vi'
OR domainname LIKE '%.vn'
OR domainname LIKE '%.vu'
OR domainname LIKE '%.wf'
OR domainname LIKE '%.ws'
OR domainname LIKE '%.ye'
OR domainname LIKE '%.yt'
OR domainname LIKE '%.yu'
OR domainname LIKE '%.za'
OR domainname LIKE '%.zm'
OR domainname LIKE '%.zw'"

/usr/bin/mysqlcheck -uroot -p$sqlpass --auto-repair -o avex

echo " 
Creating backup ... 
### <=================================================================================================> ###
" >> $ManLog

mkdir /backup-local-$Domain

cp -Rap /var/www/avex /backup-local-$Domain/avex-$Domain-$ManData
/usr/bin/mysqldump -uroot -p$sqlpass avex --lock-all-tables > /backup-local-$Domain/avex-$Domain-$ManData/dump-avex-$Domain-$ManData.sql

cp -Rap /home/$SendingUser/websites /backup-local-$Domain/websites-$Domain-$ManData
/usr/bin/mysqldump -uroot -p$sqlpass websites --lock-all-tables > /backup-local-$Domain/websites-$Domain-$ManData/dump-web-$Domain-$ManData.sql

tar -zcf /root/mailamigos-scripts/backup-local/$ArqBackup /backup-local-$Domain
rm -rf /backup-local-$Domain

echo "
Restarting services ... 
### <=================================================================================================> ###
" >> $ManLog

/etc/init.d/pmta start >> /dev/null 2>&1; sleep 120 && /etc/init.d/pmta start >> /dev/null 2>&1
/etc/init.d/named start >> /dev/null 2>&1; sleep 60 && /etc/init.d/named start >> /dev/null 2>&1
/etc/init.d/postfix start >> /dev/null 2>&1; sleep 30 && /etc/init.d/postfix start >> /dev/null 2>&1
/etc/init.d/httpd start >> /dev/null 2>&1; sleep 15 && /etc/init.d/httpd start >> /dev/null 2>&1
/etc/init.d/dovecot start >> /dev/null 2>&1 && /etc/init.d/dovecot start >> /dev/null 2>&1

echo "
Analyze resources ... 
### <=================================================================================================> ###
" >> $ManLog

/bin/sync && /bin/echo 3 > /proc/sys/vm/drop_caches >> /dev/null 2>&1

/etc/init.d/mysqld status >> $ManLog
    if [ $? -ne 0 ]
    then
        /etc/init.d/mysqld restart >> $ManLog
        sleep 30
        /etc/init.d/mysqld status >> $ManLog
            if [ $? -ne 0 ]
            then 
                echo "Error == Mysql down " >> $ManLog
            else
                echo "Error == Mysql restart " >> $ManLog
            fi
    fi

/etc/init.d/httpd status >> $ManLog
    if [ $? -ne 0  ]
    then
        /etc/init.d/httpd restart >> $ManLog
        sleep 30
        /etc/init.d/httpd status >> $ManLog
            if [ $? -ne 0 ]
            then 
                echo "Error = = Apache down " >> $ManLog
            else
                echo "Error == Apache restart " >> $ManLog
            fi
    fi

/etc/init.d/dovecot status  >> $ManLog
    if [ $? -ne 0  ]
    then
        /etc/init.d/dovecot restart >> $ManLog
        sleep 30
        /etc/init.d/dovecot status >> $ManLog
            if [ $? -ne 0 ]
            then
                echo "Error == Dovecot down " >> $ManLog
            else
                echo "Error == Dovecot restart " >> $ManLog
            fi
    fi

/etc/init.d/postfix status >> $ManLog
    if [ $? -ne 0  ]
    then
        /etc/init.d/postfix restart >> $ManLog
        sleep 30
        /etc/init.d/postfix status >> $ManLog
            if [ $? -ne 0 ]
            then 
                echo "Error == Postfix down " >> $ManLog
            else
                echo "Error == Postfix restart " >> $ManLog
            fi
    fi

/etc/init.d/named status >> $ManLog
    if [ $? -ne 0  ]
    then
        /etc/init.d/named restart >> $ManLog
        sleep 30
        /etc/init.d/named status >> $ManLog
            if [ $? -ne 0 ]
            then 
                echo "Error == Named down " >> $ManLog
            else
                echo "Error == Named restart " >> $ManLog
            fi
    fi

ls /var/spool/ |grep pmta >> /dev/null 
    if [ $? -ne 0 ]
    then 
        /etc/init.d/pmta stop >> $ManLog
        mkdir /var/spool/pmta
        chown pmta:pmta /var/spool/pmta
        /etc/init.d/pmta restart >> $ManLog
        sleep 90
        echo "Error ==/var/spool/pmta Folder re-created, pmta restarted " >> $ManLog
    fi

/etc/init.d/pmta status >> $ManLog
    if [ $? -ne 0  ]
    then
        /etc/init.d/pmta restart >> $ManLog
        sleep 90
        /etc/init.d/pmta status >> $ManLog
            if [ $? -ne 0 ]
            then 
                echo "Error == PowerMTA down " >> $ManLog
            else
                echo "Error == PowerMTA restart " >> $ManLog
            fi
    fi

/sbin/service pmtahttp status >> $ManLog
   if [ $? = 0  ]
   then
        /usr/bin/w | grep root >> $ManLog
            if [ $? -ne 0 ]
            then 
                /sbin/service pmtahttp stop >> $ManLog
                echo "Error == PMTA-http restart " >> $ManLog
            fi
    fi

/etc/init.d/crond start >> /dev/null 2>&1 && /etc/init.d/crond start >> /dev/null 2>&1

grep Erro $ManLog >> /dev/null 2>&1
    if [ $? -ne 0 ]
    then    
        echo "
        maintenance Ok ! ( Ok )
### <=================================================================================================> ###
" >> $ManLog
    else
        echo "
        Server failure, Maintenance points. (Error)
### <=================================================================================================> ###
" >> $ManLog
    fi

cat $ManLog >> /var/log/pmta/log
cat $ManLog >> /var/log/messages

Versao=`cut -d" " -f3 /etc/redhat-release | cut -d"." -f1`
    if [ $Versao = 6 ]
    then
        cat $ManLog | mail -r manutencao@server.$Domain -s "Maintenance of the server. $Domain in $Data! " $MonitoringEmail
    else
        cat $ManLog | mail -s "Maintenance of the server. $Domain in $Data! " $MonitoringEmail -- -f manutencao@server.$Domain
    fi

/etc/init.d/crond start >> /dev/null 2>&1 && /etc/init.d/crond start >> /dev/null 2>&1

