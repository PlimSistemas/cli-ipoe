#!/bin/bash

. /system/clish/bin/functions.sh


# SET
#------------------------------------------------
	if [ "$1" != "" ]; then
	
		hostname "${1}"
		echo "${1}" > /etc/hostname
		sed -i "s|^127\.0\.0\.1.*$|127.0.0.1 localhost $1|" /etc/hosts
	
		sql_exec "delete from configs where path = 'system hostname';"
		sql_exec "insert into configs (path, value1) values ('system hostname', \"$1\");"
		
	fi
	