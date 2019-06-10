#!/bin/bash



# IMPORT SCRIPT SQL
#------------------------------------------------
	. /system/clish/bin/functions.sh	


# VERIFICA BACKUP ATIVADO
#------------------------------------------------
	folder=$(sql_exec "select value1 from configs where path = 'system backup folder';")
	status=$(sql_exec "select value1 from configs where path = 'system backup enable';")

	if [ "$status" != "1" ]; then
		echo "Backup não está ATIVADO!"
		exit 0
	fi
	
	if [ "$folder" == "" ]; then
		echo "Pasta do backup nao esta configurada!"
		exit 0
	fi	


# VARIAVEIS
#------------------------------------------------
	mkdir -p /system/backup
	TIME="$(date +%Y%m%d)"
	FILENAME=backup-$TIME.tar


# COMPACTA ARQUIVOS
#------------------------------------------------
	tar -cf /system/backup/$FILENAME /etc/network/interfaces
	tar -rf /system/backup/$FILENAME /system/configs/accel-ppp/accel-ppp.conf
	tar -rf /system/backup/$FILENAME /system/configs/accel-ppp/accel-ppp.lua
	tar -rf /system/backup/$FILENAME /system//configs/accel-ppp/chap-secrets
	tar -rf /system/backup/$FILENAME /system/configs/snmp/snmpd.conf
	tar -rf /system/backup/$FILENAME /system/configs/frr/frr.conf
	tar -rf /system/backup/$FILENAME ~/.gdrive

# FAZ UPLOAD
#------------------------------------------------
	gdrive upload -p "$folder" /system/backup/$FILENAME
	
	
#para obter a pasta use o comando: gdrive list --absolute --name-width 100 -m 100	