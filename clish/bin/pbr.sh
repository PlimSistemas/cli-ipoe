#!/bin/bash

. /system/clish/bin/functions.sh


# VARIABLES
#------------------------------------------------
	path="\"ip route pbr $1 $3\""


# FUNCAO LIMPAR RULES
#------------------------------------------------
clean_rules () {
		LINES=$(ip rule list | grep "lookup PBR_$1" | awk '{print $3}')

		for IP in $LINES
		do
			$(ip rule delete from $IP table PBR_$1 > /dev/null 2>&1)
		done

}

# FUNCAO ADD RULES
#------------------------------------------------
add_rules () {

		LINES=$(sql_exec "select value1 from configs where path = \"ip route pbr $1 src\";")

		for IP in $LINES
		do
			$(ip rule add from $IP table PBR_$1)
		done
		
}



# NEXT-HOP SHOW
#------------------------------------------------
	if [ "$2" == "show" ] && [ "$3" == "hop" ]; then
		sql_exec "select value1 from configs where path = $path;"
	fi

# NEXT-HOP SET
#--------------------------------------------------------------------------------------
	if [ "$2" == "set" ] && [ "$3" == "hop" ] && [ "$4" != "" ]; then
		sql_exec "DELETE FROM configs where path = $path;"
		sql_exec "INSERT INTO configs (path, value1) values ($path, \"$4\");"
		$(ip route flush table PBR_$1 > /dev/null 2>&1)
		clean_rules $1
		$(ip route add table PBR_$1 default nexthop via $4)
		add_rules $1
	fi
#--------------------------------------------------------------------------------------

# NEXT-HOP DELETE
#------------------------------------------------
	if [ "$2" == "del" ] && [ "$3" == "hop" ]; then
		sql_exec "DELETE FROM configs where path = $path;"
		$(ip route flush table PBR_$1 > /dev/null 2>&1)
		clean_rules $1
	fi
#--------------------------------------------------------------------------------------



# SRC-ADDRESS SHOW
#------------------------------------------------
	if [ "$2" == "show" ] && [ "$3" == "src" ]; then
		sql_exec "select value1 from configs where path = $path;"
	fi

# SRC-ADDRESS SET
#------------------------------------------------
	if [ "$2" == "set" ] && [ "$3" == "src" ] && [ "$4" != "" ]; then
		sql_exec "DELETE FROM configs where path = $path and value1 = \"$4\";"
		sql_exec "INSERT INTO configs (path, value1) values ($path, \"$4\");"
		clean_rules $1
		add_rules $1
	fi


# SRC-ADDRESS DELETE
#------------------------------------------------
	if [ "$2" == "del" ] && [ "$3" == "src" ] && [ "$4" != "" ]; then
		sql_exec "DELETE FROM configs where path = $path and value1 = \"$4\";"
		clean_rules $1
		add_rules $1
	fi



# DELETE ALL PBR
#------------------------------------------------
	if [ "$2" == "del" ] && [ "$3" == "pbr" ]; then

		read -p "Voce tem certeza que deseja deletar PBR (next-hop e todos src-address do PBR)? [s,n]? " -n 1 -r
		echo    #move to a new line
		if [[ $REPLY =~ ^[Ss]$ ]]
		then
			p1="\"ip route pbr $1 hop\""
			p2="\"ip route pbr $1 src\""
			sql_exec "DELETE FROM configs where path = $p1;"
			sql_exec "DELETE FROM configs where path = $p2;"
			$(ip route flush table PBR_$1 > /dev/null 2>&1)
			clean_rules $1
		fi
	fi



# DELETE ALL SRC-ADDRESS
#------------------------------------------------
	if [ "$2" == "del" ] && [ "$3" == "src" ] && [ "$4" == "" ]; then

		read -p "Voce tem certeza que deseja deletar todos SRC-ADDRESS do PBR? [s,n]? " -n 1 -r
		echo    #move to a new line
		if [[ $REPLY =~ ^[Ss]$ ]]
		then
			sql_exec "DELETE FROM configs where path = $path;"
			clean_rules $1
		fi

	fi



# SHOW ALL PBR
#------------------------------------------------
	if [ "$2" == "show" ] && [ "$3" == "pbr" ]; then
		p1="\"ip route pbr $1 hop\""
		p2="\"ip route pbr $1 src\""
		hop=$(sql_exec "select value1 from configs where path = $p1;")
		src=$(sql_exec "select '\t' || value1 || ';' from configs where path = $p2;")
		[ -z "$hop" ] && s1="" || s1="\nnext-hop $hop;"
		[ -z "$src" ] && s2="" || s2="\nsrc-address {\n$src \n}"

		echo -e "$s1$s2\n"
	fi


# RELOAD PBR
#--------------------------------------------------------------------------------------
	if [ "$2" == "reload" ]; then
	
		hop=$(sql_exec "select value1 from configs where path = \"ip route pbr $1 hop\";")
		src=$(sql_exec "select value1 from configs where path = \"ip route pbr $1 src\";")
		
		if [ -z "$hop" ] || [ -z "$src" ]; then
			echo "PBR não ativado!  src-address ou next-hop não configurado"
			exit 0
		fi
	
		$(ip route flush table PBR_$1 > /dev/null 2>&1)
		clean_rules $1
		$(ip route add table PBR_$1 default nexthop via $hop)
		add_rules $1
	fi
#--------------------------------------------------------------------------------------