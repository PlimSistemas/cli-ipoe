#!/bin/bash

. /system/clish/bin/functions.sh


# LIST
#------------------------------------------------
	if [ "$1" == "list" ]; then
		getent passwd {1000..60000} | awk -F: '{ print $1}'
		exit 0
	fi


# DELETE
#------------------------------------------------

	if [ "$2" == "admin" ]; then
		echo "Nao e permitido excluir o usuario ADMIN"
		exit 0
	fi
	
	if [ "$1" == "del" ]; then
		userdel $2 > /dev/null 2>&1
		rm -rf /home/$2 > /dev/null 2>&1
		sql_exec "DELETE FROM configs where path = 'system login user' and value1 = \"$2\";"
		exit 0
	fi
	

# ADD
#------------------------------------------------
	if [ "$1" == "add" ]; then
		password=$(echo $3 | openssl passwd -1 -stdin)
		
		useradd -m $2 > /dev/null 2>&1
		usermod -a -G CLI $2
		usermod --shell /usr/bin/klish $2 > /dev/null 2>&1
		usermod --password $password $2 > /dev/null 2>&1		

		sql_exec "INSERT INTO configs (path, value1, value2) values ('system login user', \"$2\", \"$password\");"
		
fi
