#!/bin/bash

# REAL FILE NAME
#------------------------------------------------

	case "$2" in
		"accel")
			file_name=$(cat /etc/accel-ppp.conf | grep log-file= | sed 's/log-file=//g' | tr -d '[[:space:]]')
			;;
		"auth-fail")
			file_name=$(cat /etc/accel-ppp.conf | grep log-fail-file= | sed 's/log-fail-file=//g' | tr -d '[[:space:]]')
			;;
		"core")
			file_name=$(cat /etc/accel-ppp.conf | grep log-error= | sed 's/log-error=//g' | tr -d '[[:space:]]')
			;;
		"debug")
			file_name=$(cat /etc/accel-ppp.conf | grep log-debug= | sed 's/log-debug=//g' | tr -d '[[:space:]]')
			;;
		"emerg")
			file_name=$(cat /etc/accel-ppp.conf | grep log-emerg= | sed 's/log-emerg=//g' | tr -d '[[:space:]]')
			;;	
		*)
			file_name="$2"
			;;			
	esac


# SHOW
#------------------------------------------------
	if [ "$1" == "show" ]; then
	
		if [ "$3" == "analyzer" ] || [ "$3" == "" ]; then
			sudo less -R -i "$file_name"
		fi				

		if [ "$3" == "real-time" ]; then
			sudo less -R -i +F "$file_name"
		fi
		
	fi
	

# CLEAR
#------------------------------------------------
	if [ "$1" == "clear" ]; then


		if [ "$file_name" == "all" ]; then
			file_name1=$(cat /etc/accel-ppp.conf | grep log-file= | sed 's/log-file=//g' | tr -d '[[:space:]]')
			file_name2=$(cat /etc/accel-ppp.conf | grep log-fail-file= | sed 's/log-fail-file=//g' | tr -d '[[:space:]]')
			file_name3=$(cat /etc/accel-ppp.conf | grep log-error= | sed 's/log-error=//g' | tr -d '[[:space:]]')
			file_name4=$(cat /etc/accel-ppp.conf | grep log-debug= | sed 's/log-debug=//g' | tr -d '[[:space:]]')	
			file_name5=$(cat /etc/accel-ppp.conf | grep log-emerg= | sed 's/log-emerg=//g' | tr -d '[[:space:]]')
			sudo echo "" > "$file_name1"
			sudo echo "" > "$file_name2"
			sudo echo "" > "$file_name3"
			sudo echo "" > "$file_name4"
			sudo echo "" > "$file_name5"
			exit 0
		fi

		sudo echo "" > "$file_name"
	
	fi
	
	
