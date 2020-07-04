#!/bin/bash

. /system/clish/bin/functions.sh

action=$1
field=$2
value=$3

# SET
#------------------------------------------------
	if [ "$action" == "set" ]; then
		sql_exec "update configs set $field = \"$value\" where path = 'system connection';"
	fi
#------------------------------------------------


# DEL
#------------------------------------------------
	if [ "$action" == "del" ]; then

		#Single value
		if [ "$field" != "all" ]; then
			$(sql_exec "update configs set $field = null where path = 'system connection';")
		fi		

		#Multiple Values
		if [ "$field" == "all" ]; then
			read -p "Voce tem certeza que remover as configurações de conexão ? [s,n]? " -n 1 -r
			echo    #move to a new line
			if [[ $REPLY =~ ^[Ss]$ ]]
			then
				$(sql_exec "update configs set value1 = null where path = 'system connection';")
				$(sql_exec "update configs set value2 = null where path = 'system connection';")
				$(sql_exec "update configs set value3 = null where path = 'system connection';")
			fi
		fi

	fi
#------------------------------------------------


# SHOW
#------------------------------------------------
	if [ "$action" == "show" ]; then
		
		#Single value
		if [ "$field" != "all" ]; then
			echo -e $(sql_exec "select $field from configs where path = 'system connection';")
		fi		

		#Multiple Values
		if [ "$field" == "all" ]; then
			host=$(sql_exec "select value1 from configs where path = 'system connection';")
			port=$(sql_exec "select value2 from configs where path = 'system connection';")
			pass=$(sql_exec "select value3 from configs where path = 'system connection';")
			echo -e "Host: $host"
			echo -e "Port: $port"
			echo -e "Pass: $pass"
		fi

	fi
#------------------------------------------------

# GET-CMD
#------------------------------------------------
	if [ "$action" == "get-cmd" ]; then
		host=$(sql_exec "select value1 from configs where path = 'system connection';")
		port=$(sql_exec "select value2 from configs where path = 'system connection';")
		pass=$(sql_exec "select value3 from configs where path = 'system connection';")
		echo "accel-cmd -H $host -p $port -P $pass"
	fi
#------------------------------------------------




	