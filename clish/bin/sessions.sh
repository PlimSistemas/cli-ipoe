#!/bin/bash

# FIELDS
#------------------------------------------------
	fields="ifname,username,calling-sid,ip,tx-bytes,rx-bytes,rate-limit,state,uptime"


# SHOW
#------------------------------------------------
	if [ "$1" == "show" ]; then
		accel-cmd show sessions "$fields"
	fi


# COUNT
#------------------------------------------------
	if [ "$1" == "count" ]; then

		echo "[Total]"
		accel-cmd show stat | grep -A 3 "sessions:" | sed -e "1d"

		echo "[PPPoE]"
		accel-cmd show stat | grep -A 9 "pppoe:" | sed -e "1d"

		echo "[IPoE]"
		accel-cmd show stat | grep -A 3 "ipoe:" | sed -e "1d"
	fi

# MATCH IP
#------------------------------------------------
	if [ "$1" == "ip" ]; then
		accel-cmd show sessions "$fields" match ip "$2"
	fi


# MATCH USERNAME
#------------------------------------------------
	if [ "$1" == "username" ]; then	
		accel-cmd show sessions "$fields" match username "$2"
	fi


# MATCH VLAN
#------------------------------------------------
	if [ "$1" == "vlan" ]; then
		accel-cmd show sessions "$fields" match called-sid "$2"
	fi



# BANDWIDTH
#------------------------------------------------
	if [ "$1" == "bandwidth" ]; then

		ifname=$(accel-cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo bmon -b -o curses:details -p "$ifname"
		fi
	fi



# PING
#------------------------------------------------
	if [ "$1" == "ping" ]; then

		ip_address=$(sudo accel-cmd show sessions ip match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ip_address"; then
			echo "Subscriber not conected!"
		else
			ping -c 5 "$ip_address"
		fi

	fi



# DISCONECT
#------------------------------------------------
	if [ "$1" == "disconect" ]; then

		ifname=$(sudo accel-cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo accel-cmd terminate if "$ifname"
		fi

	fi



# TOUCH
#------------------------------------------------
	if [ "$1" == "touch" ]; then

		ifname=$(sudo accel-cmd show sessions ifname match username $2 | sed -n "3p" | tr -d '[[:space:]]')

		if test -z "$ifname"; then
			echo "Subscriber not conected!"
		else
			sudo iptraf-ng -i "$ifname"
		fi

	fi
