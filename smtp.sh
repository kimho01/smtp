#!/bin/bash

echo '

### README ### <=========================================================================================> ###
### README ### <============ WWW.ramuel.COM - PowerMTA ONLY ##NO MAILING APPLICATION## ==============> ###
### README ### <=========================================================================================> ###

' 

echo "Installing MailAmigos PowerMTA Only Version, Preparing folders please wait ... "

chmod 777 mailamigos/ -R
mv mailamigos / 
cd /mailamigos/mailamigos-scripts/
chmod 777 ./pmtainstaller6.sh.x
chmod 777 ./pmtainstaller7.sh

	if [ `/usr/bin/getconf LONG_BIT` != 64 ] 
	then 
		echo "Operating system installed on 32-bit, canceled installation ! "
		echo "Reinstall the operating system with CentOS 6 64 bits ! "
		exit
	fi

	if [ `grep -o CentOS /etc/redhat-release` != CentOS ]
	then 
		echo "CentOS not detected, canceled installation ! "
		echo "Reinstall the operating system with CentOS 6 64 bits ! "
		exit
	fi

Release6=`cut -d " " -f 3 /etc/redhat-release | cut -d "." -f 1`
Release7=`cut -d " " -f 4 /etc/redhat-release | cut -d "." -f 1`
	if [ $Release6 == 6 ]
	then
		echo "CentOS 6X 64Bits detected, initiating installation ... "
		./pmtainstaller6.sh.x
		elif [ $Release7 == 7 ]
	then
		echo "CentOS 7 64Bit detected by starting installation ... "
		./pmtainstaller7.sh
	else
		echo "CentOS detected unsupported, canceled installation ! "
		echo "Reinstall the operating system with CentOS 6 64 bits ! "
		echo "Cleaning installation ... " 

		ln -sf /dev/null /root/.bash_history
		rm -rf /autopmta*
		rm -rf /root/autopmta*
		rm -rf /supermta*
		rm -rf /mailamigosv5.zip*
		rm -rf /root/autopmta*
		rm -rf /script*
		rm -rf /root/script*
		rm -rf /tmp/*

		exit
	fi

echo "Cleaning installation ... " 

ln -sf /dev/null /root/.bash_history
rm -rf /autopmta*
rm -rf /root/autopmta*
rm -rf /supermta*
rm -rf /root/autopmta*
rm -rf /script*
rm -rf /tmp/*
rm -rf /mailamigosv5.zip*
rm -rvf /mailamigosv5.zip

reboot

