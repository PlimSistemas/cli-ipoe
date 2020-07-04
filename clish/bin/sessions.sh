#!/bin/bash

. /system/clish/bin/functions.sh
accel_cmd=$(accel_con)

# FIELDS
#------------------------------------------------
	fields="called-sid,ifname,username,calling-sid,ip,tx-bytes,rx-bytes,rate-limit,state,uptime"


# SHOW
#------------------------------------------------
	if [ "$1" == "show" ] && [ "$2" == "" ]; then
		run-command $accel_cmd show sessions "$fields" | less
		exit
	fi


# COUNT
#------------------------------------------------
	if [ "$1" == "count" ]; then

		echo "[Total]"
		run-command $accel_cmd show stat | grep -A 3 "sessions:" | sed -e "1d"

		echo "[PPPoE]"
		run-command $accel_cmd show stat | grep -A 9 "pppoe:" | sed -e "1d"

		echo "[IPoE]"
		run-command $accel_cmd show stat | grep -A 3 "ipoe:" | sed -e "1d"
	fi


# MATCH
#------------------------------------------------
	if [ "$1" == "show" ]; then	

		LIST="$(run-command $accel_cmd show sessions $fields)"
		HEAD="$(echo "$LIST" | grep -A 1 ifname)"
		
		FIST="${3:0:1}"
		LAST="${3: -1}"
		
		VALUE="$3"

		#exato ex: 127.0.0.1 
		if [ "$FIST" != "*" ] && [ "$LAST" != "*" ]; then
			SEARCH="^$VALUE$"
		fi


		#parcial ex: *.80.44.* 
		if [ "$FIST" == "*" ] && [ "$LAST" == "*" ]; then
			VALUE=${VALUE#?}
			VALUE=${VALUE%?}
			SEARCH="$VALUE"
		fi
		
		#inicia ex: 127.0.0.*
		if [ "$FIST" != "*" ] && [ "$LAST" == "*" ]; then
			VALUE=${VALUE%?}
			SEARCH="^$VALUE"
		fi
		
		#termina ex: *.0.0.1
		if [ "$FIST" == "*" ] && [ "$LAST" != "*" ]; then
			VALUE=${VALUE#?}
			SEARCH="$VALUE$"
		fi	


		IFS='
		'
		
		if [ "$2" == "vlan" ]; then
			LINES="$(echo "$LIST" | awk '{print $1}' | grep -n $SEARCH | cut -f1 -d ":")"
		fi

		if [ "$2" == "interface" ]; then
			LINES="$(echo "$LIST" | awk '{print $3}' | grep -n $SEARCH | cut -f1 -d ":")"
		fi

		if [ "$2" == "username" ]; then
			LINES="$(echo "$LIST" | awk '{print $5}' | grep -n $SEARCH | cut -f1 -d ":")"
		fi

		if [ "$2" == "ip" ]; then
			LINES="$(echo "$LIST" | awk '{print $9}' | grep -n $SEARCH | cut -f1 -d ":")"
		fi
		
		if [ "$2" == "ip6" ]; then
			LINES="$(echo "$LIST" | awk '{print $11}' | grep -n $SEARCH | cut -f1 -d ":")"
		fi
	
	fi
	
	
	

# MATCH
#------------------------------------------------
		
	for LINE in $LINES
	do
		LINHAS+="; $LINE"
		LINHAS+="p"
	done
	
	#echo "$LINES"
	
	echo "$HEAD"
	echo "$LIST" | sed -n "$LINHAS" | grep --color=always "$VALUE"


# BANDWIDTH
#------------------------------------------------
	if [ "$1" == "bandwidth" ]; then

		ifname=$(run-command $accel_cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo bmon -b -o curses:details -p "$ifname"
		fi
	fi



# PING
#------------------------------------------------
	if [ "$1" == "ping" ]; then

		ip_address=$(sudo $accel_cmd show sessions ip match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ip_address"; then
			echo "Subscriber not conected!"
		else
			ping -c 5 "$ip_address"
		fi

	fi



# DISCONECT
#------------------------------------------------
	if [ "$1" == "disconect" ]; then

		ifname=$(sudo run-command $accel_cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo run-command $accel_cmd terminate if "$ifname"
		fi

	fi



# TOUCH
#------------------------------------------------
	if [ "$1" == "touch" ]; then

		ifname=$(sudo $accel_cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo iptraf-ng -i "$ifname"
		fi

	fi
