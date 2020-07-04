#!/bin/bash

sql_exec () {
	(
		echo -e ".timeout 2000"
		echo -e "$1"
		echo -e ".quit"
	) | sqlite3 /system/db/cfg.db	
}


accel_con () {
	host=$(sql_exec "select value1 from configs where path = 'system connection';")
	port=$(sql_exec "select value2 from configs where path = 'system connection';")
	pass=$(sql_exec "select value3 from configs where path = 'system connection';")
	echo "accel-cmd -H $host -p $port -P $pass"
}




