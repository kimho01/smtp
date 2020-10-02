#!/bin/bash

# change or add the ips in the etc/pmta config, mailamigos-scripts/ips.info and the dns information
# to see if the IP is in the IPtables and if not add it and if it's a change delete it

# --> Erase empty line from ips.info 
	echo "Current IP Addresses On Your Server:"
	awk 'NF' /root/mailamigos-scripts/ips.info

# --> Get the server ip addresses
	readarray -t thearray < /root/mailamigos-scripts/ips.info

# --> Get domain name
	Serverdom=`head -1 /root/mailamigos-scripts/domain.info`
	Serverdmn="$Serverdom.db"
	printf "
	Domain: $Serverdom
	"
	Filepath=/var/named/chroot/var/named/$Serverdmn

# --> Get config pmta subdomain	[find first string in a file]
	Subdomain=`head -1 /root/mailamigos-scripts/reversedns.info`

	echo "Subdomain: $Subdomain"
	
	counting=0
	for item in ${!thearray[@]}; do
		((counting+=1))
		if [[ "$item" == 0 ]]; then
			echo -e "\nMain IP: ${thearray[$item]}"
			echo -e "This IP address is used for ns1 (name server 1) and ${Subdomain}0 in A record. Change this IP? (y/n)"
			read Useranswer
			if [ $Useranswer = y ]; then
				echo -e "Please type the IP address:"
				read Firstipaddress			
				oldipaddr=${thearray[$item]}
				new_oldipaddr=${oldipaddr%.*}.0
				
				newipaddr=$Firstipaddress
				new_ipaddr=${newipaddr%.*}.0			
			
# --> do the change on all files
					sed -i "s/$oldipaddr/$Firstipaddress/g" /root/mailamigos-scripts/ips.info
					sed -i "s/$oldipaddr/$Firstipaddress/g" /etc/pmta/config
					sed -i "s/$oldipaddr/$Firstipaddress/g" $Filepath
					sed -i "s/$new_oldipaddr/$new_ipaddr/g" $Filepath
			elif [ $Useranswer = n ]; then
				:
			fi
			
		elif [[ "$item" == 1 ]]; then
			echo -e "\nSecondary IP: ${thearray[$item]}"
			echo -e "This IP address is used for ns2 (name server 2) and ${Subdomain}1 in A record. Change this IP? (y/n)"
			read Useranswer
			if [ $Useranswer = y ]; then
				echo -e "Please type the IP address:"
				read Secondipaddress
# --> do the change on all files
					sed -i "s/${thearray[$item]}/$Secondipaddress/g" /root/mailamigos-scripts/ips.info
					sed -i "s/${thearray[$item]}/$Secondipaddress/g" /etc/pmta/config
					sed -i "s/${thearray[$item]}/$Secondipaddress/g" $Filepath	
			elif [ $Useranswer = n ]; then
				:
			fi
		else
			echo -e "\nAdditional IP number $counting: ${thearray[$item]}"
			echo -e "Change this IP? (y/n)"
			read Useranswer
			if [ $Useranswer = y ]; then
				echo -e"Please type the IP address:"
				read Nextipaddress
# --> do the change on all files
					sed -i "s/${thearray[$item]}/$Nextipaddress/g" /root/mailamigos-scripts/ips.info
					sed -i "s/${thearray[$item]}/$Nextipaddress/g" /etc/pmta/config
					sed -i "s/${thearray[$item]}/$Nextipaddress/g" $Filepath	
			elif [ $Useranswer = n ]; then
				:
			fi		
		fi
	done
	echo -e "Editing session is finished! Here is the list of IP address you set in your server:"
	cat /root/mailamigos-scripts/ips.info

# ADD IP ADDRESS
	echo -e "Do you want to add new IP address? (y/n)"
	read Theanswer

	if [ $Theanswer = y ]; then
# --> get the last line of ips.info 
			Lastip=`tac /root/mailamigos-scripts/ips.info | egrep -m 1 .`

# --> get the number of lines in ips.info - Numofline	
			Numofline=-1
			for item in ${!thearray[@]}; do
				if [ -z ${thearray[$item]} ]; then
					continue
				fi
				((Numofline+=1))
			done
# --> increment Numofline by one -> 
			Newline=$((Numofline+1))

# --> Begin adding IP address
			echo -e "Please type the IP address"
			read Ipaddress
			echo -e $Ipaddress >> /root/mailamigos-scripts/ips.info	
							
			Latest="${Subdomain}$Numofline"
			echo $Latest

# --> create new iptable rule -> 
			Added="${Subdomain}$Newline   IN   A   $Ipaddress"
			echo $Added
# --> Append the new line ->
			sed -i "/${Latest}/a ${Added}" $Filepath

			Vmtafirstline="<virtual-mta pmta-vmta$Newline>\nsmtp-source-host $Ipaddress ${Subdomain}$Newline.$Serverdom\ndomain-key default,$Serverdom,\/etc\/pmta\/$Serverdom-dkim.key\n<domain \*>\nmax-msg-rate 250/h\n<\/domain>\n<\/virtual-mta>\n<domain ${Subdomain}$Newline.$Serverdom>\n<\/domain>"
			sed -i "/<virtual-mta-pool pmta-pool>/i $Vmtafirstline\n\n" /etc/pmta/config	

			Vmtasecondline="virtual-mta pmta-vmta$Newline"	
			sed -i "/<\/virtual-mta-pool>/i $Vmtasecondline" /etc/pmta/config

			Vmtathirdline="mail-from /@${Subdomain}$Newline.$Serverdom/ virtual-mta=pmta-vmta$Newline"	
			sed -i "/<\/pattern-list>/i $Vmtathirdline" /etc/pmta/config
	
	elif [ $Theanswer = n ]; then	
		exit 0
	fi