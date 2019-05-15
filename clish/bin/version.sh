#!/bin/bash

# SHOW VERSION
#------------------------------------------------
	info=$(sudo facter)
	arc=$(echo "$info" | grep ^hardwaremodel | sed 's/hardwaremodel => //g')	
	type=$(echo "$info" | grep ^virtual | sed 's/virtual => //g')	
	vendor=$(echo "$info" | grep ^manufacturer | sed 's/manufacturer => //g')	
	model=$(echo "$info" | grep ^productname | sed 's/productname => //g')	
	serial=$(echo "$info" | grep ^serialnumber | sed 's/serialnumber => //g')	
	uuid=$(echo "$info" | grep ^uuid | sed 's/uuid => //g')
	cpu_count=$(echo "$info" | grep ^physicalprocessorcount | sed 's/physicalprocessorcount => //g')	
	cpu_name=$(echo "$info" | grep ^processor0 | sed 's/processor0 => //g')	
	cpu_cores=$(echo "$info" | grep ^processorcount | sed 's/processorcount => //g')			
	os_family=$(echo "$info" | grep ^osfamily | sed 's/osfamily => //g')	
	os_desc=$(echo "$info" | grep ^lsbdistdescription | sed 's/lsbdistdescription => //g')	
	os_arc=$(echo "$info" | grep ^rubyplatform | sed 's/rubyplatform => //g')	

	echo
	echo "     Architecture:  $arc"
	echo "      System type:  $type"
	echo
	echo "  Hardware vendor:  $vendor"
	echo "   Hardware model:  $model"
	echo "     Hardware S/N:  $serial"
	echo "    Hardware UUID:  $uuid"
	echo
	echo "        OS Family:  $os_family"
	echo "   OS Description:  $os_desc"
	echo "  OS Architecture:  $os_arc"
	echo			
	echo "         CPU Name:  $cpu_name" 
	echo "      CPU Sockets:  $cpu_count" 
	echo "  CPU Total Cores:  $cpu_cores" 
	echo ""
	echo "        Copyright:  Danilo Cruz (danilo@plimtelecom.com.br)"
	echo 
