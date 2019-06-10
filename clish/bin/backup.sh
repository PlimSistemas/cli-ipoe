#!/bin/bash

. /system/clish/bin/functions.sh



# VARIABLES
#------------------------------------------------
	path="\"system backup folder\""	
	
	
	
# AUTH
#------------------------------------------------
	if [ "$1" == "auth" ]; then
		gdrive list --absolute --name-width 100 -m 1
	fi	
	
	
# ENABLE OU DISABLE
#------------------------------------------------
	if [ "$1" == "enable" ]; then
		sql_exec "DELETE FROM configs where path = 'system backup enable';"
		sql_exec "INSERT INTO configs (path, value1) values ('system backup enable', \"$2\");"
	fi	


	
# STATUS
#------------------------------------------------
	if [ "$1" == "show" ]; then
		status=$(sql_exec "select value1 from configs where path = 'system backup enable';")
		folder=$(sql_exec "select value1 from configs where path = 'system backup folder';")
		
		if [ "$status" == "1" ]; then
			echo "Status: ATIVADO!"
		else
			echo "Status: DESATIVADO!"			
		fi	

			echo "Folder: $folder"
		
	fi	
	
	

# DELETE 
#------------------------------------------------
	if [ "$1" == "del" ]; then	
		sql_exec "DELETE FROM configs where path = $path;"	
		exit 0
	fi
	
	
	
# SET
#------------------------------------------------
	if [ "$1" == "set" ]; then	
		sql_exec "DELETE FROM configs where path = $path;"
		sql_exec "INSERT INTO configs (path, value1) values ($path, \"$2\");"
		exit 0
	fi
	