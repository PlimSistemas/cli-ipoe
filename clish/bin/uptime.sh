#!/bin/bash

# SHOW UPTIME
#------------------------------------------------
	system=$(uptime | awk -F'( |,|:)+' '{if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0,"days,",h+0,"hours,",m+0,"minutes."}')
	accel=$(run-command -t 2 /system/clish/bin/accel.sh stat | grep uptime | sed 's/uptime\: //g' |  sed 's/\./:/g' | awk -F ':' '{print $1+0,"days,",$2+0,"hours,",$3+0,"minutes."}')
	echo "      System: $system"			
	echo "   Accel-PPP: $accel"