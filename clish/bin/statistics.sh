#!/bin/bash


	if [ "$1" != "" ]; then
		watch -n $1 accel-cmd show stat
	else
		sudo accel-cmd show stat
	fi
	
