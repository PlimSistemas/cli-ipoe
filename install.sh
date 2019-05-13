#Preparação
#------------------------------------------------
	mkdir -p /system

	
#Atualizando Pacotes
#------------------------------------------------
	apt update
	apt install -y --no-install-recommends sudo net-tools curl nmap tcpdump htop atop mtr vlan ethtool apt-transport-https ca-certificates mc bmon vlan ifenslave-2.6
	apt install -y --no-install-recommends psmisc git git-core make cmake zlib1g-dev liblua5.1-dev libpcre3-dev build-essential libssl-dev libsnmp-dev linux-headers-`uname -r`
	apt install -y --no-install-recommends dh-autoreconf libexpat1-dev telnet ntpdate ipset unzip sqlite3 libsqlite3-dev


#Instalando o FRR
#------------------------------------------------
	curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
	FRRVER="frr-stable"
	echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | sudo tee -a /etc/apt/sources.list.d/frr.list
	apt update
	apt install -y frr frr-pythontools
	
	sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
	sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
	
	mkdir -p /system/configs/frr
	mv /etc/frr/frr.conf /system/configs/frr/
	ln -s /system/configs/frr/frr.confg /etc/frr/frr.conf
	
	/etc/init.d/frr restart
	

#Instalando Accel-ppp
#------------------------------------------------
	cd /usr/local/src
	git clone git://git.code.sf.net/p/accel-ppp/code accel-ppp-code
	mkdir -p accel-ppp-build
	cd accel-ppp-build
	cmake -DKDIR=/usr/src/linux-headers-`uname -r` -DBUILD_DRIVER=FALSE -DRADIUS=TRUE -DNETSNMP=TRUE -DSHAPER=TRUE -DLOG_PGSQL=FALSE -DLUA=TRUE -DBUILD_IPOE_DRIVER=TRUE -DBUILD_VLAN_MON_DRIVER=TRUE ../accel-ppp-code
	make
	make install

	mkdir -p /var/log/accel-ppp
	chmod -R a+rwX /var/log/accel-ppp

	echo "ATTRIBUTE DHCP-Router-IP-Address 241 ipaddr" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE DHCP-Mask 242 integer" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE L4-Redirect 243 integer" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE L4-Redirect-ipset 244 string" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE DHCP-Option82 245 octets" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "#ATTRIBUTE DHCP-Agent-Circuit-Id	1 octets" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "#ATTRIBUTE DHCP-Agent-Remote-Id	2 octets" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE AccelRemoteId 246 octets" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "ATTRIBUTE AccelCircuitId 247 octets" >> /usr/local/share/accel-ppp/radius/dictionary
	echo "#ATTRIBUTE DHCP-Attr-272 272 ipaddr" >> /usr/local/share/accel-ppp/radius/dictionary
	
	mkdir -p /lib/modules/`uname -r`/accel
	cp /usr/local/src/accel-ppp-build/drivers/ipoe/driver/ipoe.ko /lib/modules/`uname -r`/accel/
	cp /usr/local/src/accel-ppp-build/drivers/vlan_mon/driver/vlan_mon.ko /lib/modules/`uname -r`/accel/
	
	cp /usr/local/src/accel-ppp-code/accel-pppd/extra/net-snmp/ACCEL-PPP-MIB.txt /usr/share/snmp/mibs/

	echo "ipv6" >> /etc/modules
	echo "ipoe" >> /etc/modules
	echo "vlan_mon" >> /etc/modules
	echo "8021q" >> /etc/modules
	echo "bonding" >> /etc/modules
	echo "dummy" >> /etc/modules

	depmod -a
	modprobe ipoe
	modprobe vlan_mon

	sed -i 's/\/usr\/sbin\/accel-pppd/\/usr\/local\/sbin\/accel-pppd/g' /usr/local/src/accel-ppp-code/contrib/debian/accel-ppp-init
	cp /usr/local/src/accel-ppp-code/contrib/debian/accel-ppp-init /etc/init.d/accel-ppp
	chmod +x /etc/init.d/accel-ppp
	update-rc.d accel-ppp defaults
	
	systemctl is-enabled accel-ppp.service
	systemctl enable accel-ppp.service


#Log Rotativo do Accel-ppp
#------------------------------------------------
	(
		echo "/var/log/accel-ppp/*.log {"
		echo "		size 50M"
		echo "        missingok"
		echo "		rotate 10"
		echo "        sharedscripts"
		echo "        postrotate"
		echo "                test -r /var/run/accel-ppp.pid && kill -HUP `cat /var/run/accel-ppp.pid`"
		echo "        endscript"
		echo "}"
	) > /etc/logrotate.d/accel-ppp

	mkdir -p /var/log/accel-ppp


#Otimizando
#------------------------------------------------
	(
		echo "net.ipv4.ip_forward=1"
		echo "net.ipv6.conf.all.forwarding=1"
		echo "net.ipv4.neigh.default.gc_thresh1 = 4096"
		echo "net.ipv4.neigh.default.gc_thresh2 = 8192"
		echo "net.ipv4.neigh.default.gc_thresh3 = 12288"
		echo "net.ipv4.netfilter.ip_conntrack_max=1572864"
		echo "net.netfilter.nf_conntrack_max = 1572864"
		echo "net.netfilter.nf_conntrack_generic_timeout = 300"
		echo "net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 60"
		echo "net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60"
		echo "net.netfilter.nf_conntrack_tcp_timeout_established = 600"
		echo "net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 60"
		echo "net.netfilter.nf_conntrack_tcp_timeout_close_wait = 45"
		echo "net.netfilter.nf_conntrack_tcp_timeout_last_ack = 30"
		echo "net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120"
		echo "net.netfilter.nf_conntrack_tcp_timeout_close = 10"
		echo "net.netfilter.nf_conntrack_tcp_timeout_max_retrans = 300"
		echo "net.netfilter.nf_conntrack_tcp_timeout_unacknowledged = 300"
		echo "net.netfilter.nf_conntrack_udp_timeout = 30"
		echo "net.netfilter.nf_conntrack_udp_timeout_stream = 60"
		echo "#net.netfilter.nf_conntrack_icmpv6_timeout = 30"
		echo "net.netfilter.nf_conntrack_icmp_timeout = 30"
		echo "net.netfilter.nf_conntrack_events_retry_timeout = 15"
		echo "net.netfilter.nf_conntrack_checksum=0"
		echo "net.ipv4.netfilter.ip_conntrack_checksum=0"
		echo "net.core.dev_weight = 16"
		echo "net.core.netdev_budget = 256"
		echo "net.core.netdev_max_backlog = 16000"
		echo "vm.swappiness = 10"
		echo "vm.dirty_background_ratio = 5"
		echo "vm.dirty_ratio = 10"
	) >> /etc/sysctl.conf

	echo "options nf_conntrack hashsize=1193572" > /etc/modprobe.d/nf_conntrack.conf

	echo "100     accel/ipoe"  >> /etc/iproute2/rt_protos
	echo "100     accel/ipoe"  >> /etc/iproute2/rt_tables	

	sysctl -p

	sed -i 's/quiet/quiet processor.max_cstate=1 intel_idle.max_cstate=0/g' /etc/default/grub
	update-grub


# CRONTAB
#------------------------------------------------
    clist="/tmp/clist"
    mkdir -p /etc/cron.hourly
    mkdir -p /etc/cron.daily
    mkdir -p /etc/cron.weekly
    mkdir -p /etc/cron.monthly
    mkdir -p /etc/cron.1min
    mkdir -p /etc/cron.5min
    mkdir -p /etc/cron.10min
    mkdir -p /etc/cron.15min
    mkdir -p /etc/cron.30min

    echo -n > $clist

    # PATH
    echo "PATH=/usr/sbin:/usr/bin:/sbin:/bin" >> $clist

    # hora
    echo "0   *   *   *   *   /bin/run-parts --regex '.*' /etc/cron.hourly" >> $clist
    # dia
    echo "0   2   *   *   *   /bin/run-parts --regex '.*' /etc/cron.daily" >> $clist
    # semana
    echo "0   3   *   *   6   /bin/run-parts --regex '.*' /etc/cron.weekly" >> $clist
    # mes
    echo "0   5   1   *   *   /bin/run-parts --regex '.*' /etc/cron.monthly" >> $clist
    # minutos 1 5 10 15 30
    for min in 1 5 10 15 30; do
	echo "*/$min   *   *   *   *   /bin/run-parts --regex '.*' /etc/cron.${min}min" >> $clist
    done
    cat $clist | crontab - 2>/dev/null 1>/dev/null

	
# Auto clean, keep up
#------------------------------------------------
    
	# Manter SNMPd rodando
    (
		echo '#!/bin/sh'
		echo
		echo 'e=$(ps ax | grep snmpd | grep -v grep)'
		echo '[ "x$e" = "x" ] && {'
		echo '    # Nao esta rodando'
		echo '    service snmpd stop'
		echo '    service snmpd start'
		echo '}'
		echo 'exit 0'
		echo
    ) > /etc/cron.1min/snmpd-keeper.sh	
    chmod +x /etc/cron.1min/snmpd-keeper.sh


    # Limpar cache de fs para deixar ram sempre disponivel para apps
    (
		echo '#!/bin/sh'
		echo
		echo 'for i in 1 2 3; do'
		echo '    echo $i > /proc/sys/vm/drop_caches'
		echo 'done'
		echo
		echo 'exit 0'
		echo
    ) > /etc/cron.hourly/fscache-clear.sh
    chmod +x /etc/cron.hourly/fscache-clear.sh
	

    # Backup automatico Google Drive
    (
		echo "#!/bin/bash"
		echo
		echo "mkdir -p /backup"
		echo "TIME=`date +%Y%m%d-%H%M%S`"
		echo "FILENAME=backup-accel-ppp-$TIME.tar"
		echo
		echo "tar -cf /backup/$FILENAME /etc/network/interfaces"
		echo "tar -rf /backup/$FILENAME /system/firewall/ipset.conf"
		echo "tar -rf /backup/$FILENAME /system/firewall/iptables.conf"
		echo "tar -rf /backup/$FILENAME /etc/accel-ppp.conf"
		echo "tar -rf /backup/$FILENAME /etc/accel-ppp.lua"
		echo "tar -rf /backup/$FILENAME /etc/chap-secrets"
		echo "tar -rf /backup/$FILENAME /etc/snmp/snmpd.conf"
		echo "tar -rf /backup/$FILENAME /etc/frr/frr.conf"
		echo "tar -rf /backup/$FILENAME ~/.gdrive"
		echo
		echo "#para obter a pasta use o comando: gdrive list --absolute --name-width 100 -m 100"
		echo "gdrive upload -p 1EU5I2lvkydowqMSnseCmYXA9Cv8mslnN /backup/$FILENAME"
		echo
		echo "exit 0"
		echo
	) > /etc/cron.daily/backup_to_gdrive.sh
    chmod +x /etc/cron.daily/backup_to_gdrive.sh
	
	
#Criando Script de Firewall
#------------------------------------------------
	mkdir -p /system/firewall
	touch /system/firewall/ipset.conf
	touch /system/firewall/iptables.conf
	
	(
		echo "#!/bin/bash"
		echo 
		echo "#Limpa Firewall"
		echo "#------------------------------------------------"
		echo "	iptables -F -t filter"
		echo "	iptables -F -t nat"
		echo "	iptables -F -t mangle"
		echo "	iptables -F -t raw"
		echo 
		echo "	iptables -X -t filter"
		echo "	iptables -X -t nat"
		echo "	iptables -X -t mangle"
		echo "	iptables -X -t raw"
		echo 
		echo "#Cria lista de IPs"
		echo "#------------------------------------------------"
		echo "	ipset destroy"
		echo "	ipset restore < /system/firewall/ipset.conf"
		echo 
		echo 
		echo "#Carrega Firewall"
		echo "#------------------------------------------------"
		echo "	iptables-restore < /system/firewall/iptables.conf"
	) > /system/firewall/firewall.sh

	chmod +x /system/firewall/firewall.sh
	ln -s /system/firewall/firewall.sh /usr/local/bin/firewall
	
	
	
#Configurando NTP Client
#------------------------------------------------
	timedatectl set-timezone America/Sao_Paulo
	ntpdate a.ntp.br
		
	
#Google Drive Client
#------------------------------------------------
	wget -O /usr/local/bin/gdrive https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download && chmod +x /usr/local/bin/gdrive
	

#Instalar klish
#------------------------------------------------
	cd /usr/local/src
	git clone https://src.libcode.org/klish
	cd klish
	sed -i 's/bool_t lockless = BOOL_FALSE/bool_t lockless = BOOL_TRUE/g' /usr/local/src/klish/bin/clish.c
	sed -i '/sigset_t sigpipe_set;/a xml_path = \"/etc/clish\";' /usr/local/src/klish/bin/clish.c
	
	./autogen.sh
	./configure --prefix=/usr
	make
	make install
	

#Instalar configs e CLI config
#------------------------------------------------	
	cd /usr/local/src
	git clone https://github.com/PlimSistemas/cli-ipoe.git cli-ipoe

	mv /usr/local/src/cli-ipoe/clish/ /system
	mv /usr/local/src/cli-ipoe/configs/accel-ppp/ /system/configs
	mv /usr/local/src/cli-ipoe/db/ /system
	mv /usr/local/src/cli-ipoe/scripts/ /system
	
	rm -rf /system/configs/snmp/snmpd.conf
	ln -s /system/configs/snmp/snmpd.conf /etc/snmp/	
	
	ln -s /system/configs/accel-ppp/* /etc/ 
	ln -s /system/clish /etc/
		
	
#Outros
#------------------------------------------------
	
	(
		echo
		echo 'export HOSTNAME=$(hostname)'
	) >> /etc/profile
	
	source /etc/profile
	
	groupadd CLI
	echo '%CLI     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
	
	(
		echo "#!/bin/bash"
		echo
		echo "export HOSTNAME=$(hostname)"
		echo "clish -l"
		echo "exit"
	) > /usr/bin/klish
	chmod +x /usr/bin/klish
	
	
	rm -rf /usr/local/scr/cli-ipoe