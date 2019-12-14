#!/bin/bash

# IMPORT SQLITE FUNCTION
#------------------------------------------------
	. /system/clish/bin/functions.sh


#Limpa Firewall
#------------------------------------------------
	nft flush ruleset


# VERIFICA FIREWALL DESATIVADO
#------------------------------------------------
	enable=$(sql_exec "select value1 from configs where path = 'system firewall enable';")
	if [ "$enable" != "1" ]; then
		echo "Configuração de Firewall está desativada!"
		exit 0
	fi





# CRIA LISTA DE IPS e PORTAS
#------------------------------------------------

	list_ssh=$(sql_exec "select value1 from configs where path = 'system firewall group acl-ssh';" | tr '\n' ' ')
	list_snmp=$(sql_exec "select value1 from configs where path = 'system firewall group acl-snmp';" | tr '\n' ' ')
	list_static_ips=$(sql_exec "select value1 from configs where path = 'system firewall group static-ip';" | tr '\n' ' ')
	list_cpe_ports=$(sql_exec "select value1 from configs where path = 'system firewall group cpe-ports';" | tr '\n' ' ')
	list_cpe_management=$(sql_exec "select value1 from configs where path = 'system firewall group cpe-management';" | tr '\n' ' ')
	list_bgp=$(sql_exec "select value1 from configs where path = 'system firewall group acl-bgp';" | tr '\n' ' ')
	list_radius_coa=$(sql_exec "select value1 from configs where path = 'system firewall group acl-radius-coa';" | tr '\n' ' ')

	read -a ar_ssh             <<< "$list_ssh"
	read -a ar_snmp            <<< "$list_snmp"
	read -a ar_static          <<< "$list_static_ips"
	read -a ar_cpe_ports       <<< "$list_cpe_ports"
	read -a ar_cpe_management  <<< "$list_cpe_management"
	read -a ar_bgp             <<< "$list_bgp"
	read -a ar_radius_coa      <<< "$list_radius_coa"


	for i in "${!ar_ssh[@]}"; do #ACL-SSH
		[ $i == 0 ] && nft_ssh="${ar_ssh[i]}" || nft_ssh="${nft_ssh}, ${ar_ssh[i]}"
	done

	for i in "${!ar_snmp[@]}"; do #ACL-SNMP
		[ $i == 0 ] && nft_snmp="${ar_snmp[i]}" || nft_snmp="${nft_snmp}, ${ar_snmp[i]}"
	done

	for i in "${!ar_cpe_ports[@]}"; do #CPE-PORTS
		[ $i == 0 ] && nft_cpe_ports="${ar_cpe_ports[i]}" || nft_cpe_ports="${nft_cpe_ports}, ${ar_cpe_ports[i]}"
	done

	for i in "${!ar_cpe_management[@]}"; do #CPE-MANAGEMENT
		[ $i == 0 ] && nft_cpe_management="${ar_cpe_management[i]}" || nft_cpe_management="${nft_cpe_management}, ${ar_cpe_management[i]}"
	done

	for i in "${!ar_static[@]}"; do #CPE-MANAGEMENT
		[ $i == 0 ] && nft_static="${ar_static[i]}" || nft_static="${nft_static}, ${ar_static[i]}"
	done

	for i in "${!ar_bgp[@]}"; do #ACL-BGP
		[ $i == 0 ] && nft_bgp="${ar_bgp[i]}" || nft_bgp="${nft_bgp}, ${ar_bgp[i]}"
	done

	for i in "${!ar_radius_coa[@]}"; do #ACL-RADIUS-COA
		[ $i == 0 ] && nft_radius_coa="${ar_radius_coa[i]}" || nft_radius_coa="${nft_radius_coa}, ${ar_radius_coa[i]}"
	done


	[ -z "$list_ssh" ]            && nft_ssh="0.0.0.0/0"              || nft_ssh="$nft_ssh"
	[ -z "$list_snmp" ]           && nft_snmp="0.0.0.0/0"             || nft_snmp="$nft_snmp"
	[ -z "$list_cpe_ports" ]      && nft_cpe_ports="0"                || nft_cpe_ports="$nft_cpe_ports"
	[ -z "$list_static_ips" ]     && nft_static="255.255.255.255/32"  || nft_static="$nft_static"
	[ -z "$list_cpe_management" ] && nft_cpe_management="0.0.0.0/0"   || nft_cpe_management="$nft_cpe_management"
	[ -z "$list_bgp" ]            && nft_bgp="0.0.0.0/0"              || nft_bgp="$nft_bgp"
	[ -z "$list_radius_coa" ]     && nft_radius_coa="0.0.0.0/0"       || nft_radius_coa="$nft_radius_coa"
	
	nft_ssh=${nft_ssh//\//\\/}
	nft_snmp=${nft_snmp//\//\\/}
	nft_cpe_ports=${nft_cpe_ports//\//\\/}
	nft_static=${nft_static//\//\\/}
	nft_cpe_management=${nft_cpe_management//\//\\/}
	nft_bgp=${nft_bgp//\//\\/}
	nft_radius_coa=${nft_radius_coa//\//\\/}

	sed -i "/define ACL_SSH/s/.*/define ACL_SSH = { $nft_ssh }/"                                      /system/firewall/nftables.conf
	sed -i "/define ACL_SNMP/s/.*/define ACL_SNMP = { $nft_snmp }/"                                   /system/firewall/nftables.conf
	sed -i "/define CPE_BLOCK_PORTS/s/.*/define CPE_BLOCK_PORTS = { $nft_cpe_ports }/"                /system/firewall/nftables.conf
	sed -i "/define IPS_PORT_WHITE_LIST/s/.*/define IPS_PORT_WHITE_LIST = { $nft_static }/"           /system/firewall/nftables.conf
	sed -i "/define CPE_BLOCK_MANAGEMENT/s/.*/define CPE_BLOCK_MANAGEMENT = { $nft_cpe_management }/" /system/firewall/nftables.conf
	sed -i "/define ACL_BGP/s/.*/define ACL_BGP = { $nft_bgp }/"                                      /system/firewall/nftables.conf
	sed -i "/define ACL_RADIUS_COA/s/.*/define ACL_RADIUS_COA = { $nft_radius_coa }/"                 /system/firewall/nftables.conf
	
	/system/firewall/nftables.conf