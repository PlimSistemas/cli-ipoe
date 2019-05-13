#!/bin/bash


sql_exec () {
	(
		echo -e ".timeout 2000"
		echo -e "$1"
		echo -e ".quit"
	) | sqlite3 /system/scripts/cfg.db	
}