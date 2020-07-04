#!/bin/bash

. /system/clish/bin/functions.sh
accel_cmd=$(accel_con)

action=$1
var1=$2
var2=$3

# VERSION
#------------------------------------------------
	if [ "$action" == "version" ]; then
		version=$(accel-cmd -V)
		echo -e "$version"
	fi
#------------------------------------------------

# VERSION
#------------------------------------------------
	if [ "$action" == "stat" ]; then
		stat=$($accel_cmd show stat)
		echo -e "$stat"
	fi
#------------------------------------------------

# SESSIONS
#------------------------------------------------
	if [ "$action" == "sessions" ]; then
		sessions=$($accel_cmd show sessions $var1)
		echo -e "$sessions"
	fi
#------------------------------------------------
