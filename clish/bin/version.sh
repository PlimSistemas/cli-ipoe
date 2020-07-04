# SHOW VERSION
#------------------------------------------------
	arc=$(uname -m)	
	vendor=$(sudo dmidecode -s system-manufacturer)
	model=$(sudo dmidecode -s system-product-name)
	serial=$(sudo dmidecode -s system-serial-number)
	uuid=$(sudo dmidecode -s system-uuid)
	cpu_count=$(cat /proc/cpuinfo | grep "physical id" | sort -u | wc -l)
	cpu_name=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed 's/model name//g' | xargs | cut -c 3-)
	cpu_cores=$(sudo nproc)
	os_family=$(sudo lsb_release -is)
	os_desc=$(sudo lsb_release -ds)

	type=$(virt-what | wc -m)
	[ -z "$type" ] && type="Bare Metal" || type="Virtual"

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
	echo
	echo "         CPU Name:  $cpu_name"
	echo "      CPU Sockets:  $cpu_count"
	echo "  CPU Total Cores:  $cpu_cores"
	echo ""
	echo "        Copyright:  Danilo Cruz (danilo@plimtelecom.com.br)"
	echo
	