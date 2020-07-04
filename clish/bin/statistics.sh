#!/bin/bash

. /system/clish/bin/functions.sh
accel_cmd=$(accel_con)

	if [ "$1" != "" ]; then
		watch -n $1 $accel_cmd show stat
	else
		sudo $accel_cmd show stat
	fi
	
