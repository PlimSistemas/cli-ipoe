#!/bin/bash

# IMPORT SQLITE FUNCTION
#------------------------------------------------
	. /system/clish/bin/functions.sh


# VARIAVEIS
#------------------------------------------------
	file_ipset="/system/firewall/ipset.conf"

#Limpa Firewall
#------------------------------------------------
	iptables -F -t filter
	iptables -F -t nat
	iptables -F -t mangle
	iptables -F -t raw
	
	iptables -X -t filter
	iptables -X -t nat
	iptables -X -t mangle
	iptables -X -t raw
	
# Limpa IPSET
#------------------------------------------------

	ip rule del pref 2 fwmark 0x80000001 table 2

	ipset destroy
	echo "" > "$file_ipset"
	
	
	
	
# VERIFICA FIREWALL DESATIVADO
#------------------------------------------------
	enable=$(sql_exec "select value1 from configs where path = 'system firewall enable';")
	if [ "$enable" != "1" ]; then
		exit 0		
	fi
	



	
	
# LIST PBR
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group pbr';" | tr '\n' ' ')
	read -a ips <<< "$list"
	
	echo -e "\ncreate pbr hash:net family inet" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add pbr $aux" >> $file_ipset
	done
	



# LIST CPE MANAGEMENT
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group cpe-management';" | tr '\n' ' ')
	read -a ips <<< "$list"
	
	echo -e "\ncreate cpe-management hash:net family inet" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add cpe-management $aux" >> $file_ipset
	done
	
	
	
# LIST CPE PORTS
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group cpe-ports';" | tr '\n' ' ')
	read -a ips <<< "$list"
	
	echo -e "\ncreate cpe-ports bitmap:port range 1-65535" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add cpe-ports $aux" >> $file_ipset
	done




# LIST STATIC-IP
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group static-ip';" | tr '\n' ' ')
	read -a ips <<< "$list"

	
	echo -e "\ncreate static-ip hash:net family inet" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add static-ip $aux" >> $file_ipset
	done
	
	
# LIST ACL SSH
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group acl-ssh';" | tr '\n' ' ')
	read -a ips <<< "$list"

	
	echo -e "\ncreate acl-ssh hash:net family inet" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add acl-ssh $aux" >> $file_ipset
	done	



# LIST ACL SSH
#------------------------------------------------
	list=$(sql_exec "select value1 from configs where path = 'system firewall group acl-snmp';" | tr '\n' ' ')
	read -a ips <<< "$list"

	
	echo -e "\ncreate acl-snmp hash:net family inet" >> $file_ipset
	
	for aux in "${ips[@]}";
	do
		echo "add acl-snmp $aux" >> $file_ipset
	done	




#Carrega Firewall
#------------------------------------------------
	ip rule add pref 2 fwmark 0x80000001 table 2

	ipset restore < /system/firewall/ipset.conf	

	#Delete interfaces ACL
	sed -i '/^-A FW_LOCAL_HOOK -i/d' /system/firewall/iptables.conf
	
	#Delete PBR
	sed -i '/^-A CGNAT -m comment --comment/d' /system/firewall/iptables.conf

	
	#Adiciona Interface ACL
	list=$(sql_exec "select value1 from configs where path = 'system firewall group acl-interface';" | tr '\n' ' ')
	read -a ifname <<< "$list"
	
	for aux in "${ifname[@]}";
	do
		sed -i "/^#PROTECT-BEGIN/a -A FW_LOCAL_HOOK -i $aux -j    RE-PROTECT" /system/firewall/iptables.conf
	done	
	

	#Adiciona PBR
	list=$(sql_exec "select value1 from configs where path = 'system firewall group pbr';" | tr '\n' ' ')
	read -a redes <<< "$list"
	
	for aux in "${redes[@]}";
	do
		sed -i "/^#PBR-BEGIN/a -A CGNAT -m comment --comment \"CGNAT\" --source $aux --destination 0.0.0.0/0 -j PBR_2" /system/firewall/iptables.conf
	done	
	
	
	iptables-restore < /system/firewall/iptables.conf
