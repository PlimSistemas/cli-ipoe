#!/bin/bash

. /system/scripts/functions.sh


# LIST
#------------------------------------------------
	if [ "$1" == "list" ]; then
		getent passwd {1000..60000} | awk -F: '{ print $1}'
		exit 0
	fi


# DELETE
#------------------------------------------------
	if [ "$1" == "del" ]; then
		userdel $2 > /dev/null 2>&1
		rm -rf /home/$2 > /dev/null 2>&1
		sql_exec "DELETE FROM configs where path = 'system login user' and value1 = \"$2\";"
		exit 0
	fi
	

# ADD
#------------------------------------------------
	if [ "$1" == "add" ]; then
	
		# Verifica se usuário já existe
		user=$(sql_exec "select * from configs where path = 'system login user' and value1 = \"$3\";")		
		IFS='|' read -r -a config <<< "$user"
		
		if [ "${config[1]}" == "$2" ]; then
			echo "Username already exists!"
			exit 0
		fi


		password=$(echo $3 | openssl passwd -1 -stdin)
		
		useradd -m $2 > /dev/null 2>&1
		usermod -a -G CLI $2
		usermod --shell /usr/bin/klish $2 > /dev/null 2>&1
		usermod --password $password $2 > /dev/null 2>&1		

		sql_exec "INSERT INTO configs (path, value1, value2) values ('system login user', \"$2\", \"$password\");"
		
fi
