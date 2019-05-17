#!/bin/bash

. /system/clish/bin/functions.sh



# VARIABLES
#------------------------------------------------
	path="\"system firewall group $2\""	
	
	
	
# ENABLE OU DISABLE
#------------------------------------------------
	if [ "$1" == "enable" ]; then
		sql_exec "DELETE FROM configs where path = 'system firewall enable';"
		sql_exec "INSERT INTO configs (path, value1) values ('system firewall enable', \"$2\");"
	fi	


	
# STATUS
#------------------------------------------------
	if [ "$1" == "status" ]; then
		status=$(sql_exec "select value1 from configs where path = 'system firewall enable';")
		
		if [ "$status" == "1" ]; then
			echo "Firewall esta ATIVADO!"
		else
			echo "Firewall esta DESATIVADO!"			
		fi				
		
	fi	
	
	

# DELETE SPECIFIC CHAIN
#------------------------------------------------
	if [ "$1" == "del" ] && [ "$2" != "" ] && [ "$3" == "" ]; then
	
		read -p "Voce tem certeza que deseja deletar grupo [$2]? [s,n]? " -n 1 -r
		echo    #move to a new line
		if [[ $REPLY =~ ^[Ss]$ ]]
		then
			sql_exec "DELETE FROM configs where path = $path;"
		fi		
	
		exit 0
	fi
	
	
# ADD CHAIN
#------------------------------------------------
	if [ "$1" == "add" ] && [ "$2" != "" ] && [ "$3" != "" ]; then
		sql_exec "DELETE FROM configs where path = $path and value1 = \"$3\";"
		sql_exec "INSERT INTO configs (path, value1) values ($path, \"$3\");"
	fi
	
	
# DELETE CHAIN
#------------------------------------------------
	if [ "$1" == "del" ] && [ "$2" != "" ] && [ "$3" != "" ]; then
		sql_exec "DELETE FROM configs where path = $path and value1 = \"$3\";"
	fi
		

# LIST CHAIN
#------------------------------------------------
	if [ "$1" == "list" ] && [ "$2" != "" ]; then
		sql_exec "select value1 from configs where path = $path;"
	fi
	