#!/bin/bash
	
#Atualizando Pacotes
#------------------------------------------------
	apt update
	apt upgrade
	apt remove -y --purge iptables
	apt install -y --no-install-recommends sudo net-tools curl nmap tcpdump htop atop mtr vlan ethtool apt-transport-https ca-certificates gnupg gnupg2 gnupg1 ruby mc bmon vlan ifenslave-2.6
	apt install -y --no-install-recommends psmisc git git-core make cmake zlib1g-dev liblua5.1-dev libpcre3-dev build-essential libssl-dev libsnmp-dev linux-headers-`uname -r`
	apt install -y --no-install-recommends virt-what dh-autoreconf libexpat1-dev telnet ntpdate ipset unzip sqlite3 libsqlite3-dev libperl-dev iptraf conntrack linux-perf neofetch nftables 




mkdir -p /usr/local/src/accel/build
cd /usr/local/src/accel
git clone https://github.com/xebd/accel-ppp.git
cd /usr/local/src/accel/build

cmake \
-DCPACK_TYPE=Debian9 \
-DBUILD_IPOE_DRIVER=TRUE \
-DBUILD_VLAN_MON_DRIVER=TRUE \
-DRADIUS=TRUE \
-DNETSNMP=TRUE \
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_INSTALL_PREFIX=/usr \
-DKDIR=/usr/src/linux-headers-$(uname -r) \
../accel-ppp

make

cp drivers/ipoe/driver/ipoe.ko /lib/modules/$(uname -r)
cp drivers/vlan_mon/driver/vlan_mon.ko /lib/modules/$(uname -r)
depmod -a
modprobe  vlan_mon
modprobe  ipoe

echo "vlan_mon" >> /etc/modules
echo "ipoe" >> /etc/modules
cpack -G DEB
apt install ./accel-ppp.deb
systemctl enable accel-ppp
cp /etc/accel-ppp.conf.dist  /etc/accel-ppp.conf
/etc/init.d/accel-ppp restart


echo
echo -e "FIM FIM FIM"
echo






exit




#Preparação
#------------------------------------------------
	mkdir -p /system
	cd /usr/local/src
	git clone https://github.com/PlimSistemas/cli-ipoe.git cli-ipoe
	

#Instalando o FRR
#------------------------------------------------
	curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
	FRRVER="frr-stable"
	echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | sudo tee -a /etc/apt/sources.list.d/frr.list
	apt update
	apt install -y frr frr-pythontools
	
	sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
	sed -i 's/ospf6d=no/ospf6d=yes/g' /etc/frr/daemons
	sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
	
	mkdir -p /system/configs/frr
	mv /etc/frr/frr.conf /system/configs/frr/
	ln -s /system/configs/frr/frr.conf /etc/frr/frr.conf
	
	/etc/init.d/frr restart
	
	
	
#Instalando SNMP
#------------------------------------------------
	unzip /usr/local/src/cli-ipoe/others/net-snmp-5.8.zip -d /usr/local/src/
	cd /usr/local/src/net-snmp-5.8
	./configure --with-default-snmp-version="2" --with-sys-contact="noc" --with-sys-location="noc" --with-logfile="/var/log/snmpd.log" --with-persistent-directory="/var/net-snmp" --exec_prefix=/usr --prefix=/usr
	make
	make install

	cp /usr/local/src/cli-ipoe/others/snmpd /etc/init.d/
	chmod +x /etc/init.d/snmpd
	update-rc.d snmpd defaults

#Instalando Accel-ppp
#------------------------------------------------
	mkdir -p cd /usr/local/src/accel-ppp-build
	git clone git://git.code.sf.net/p/accel-ppp/code /usr/local/src/accel-ppp-code

	cd /usr/local/src/accel-ppp-build
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCPACK_TYPE=Debian9 -DKDIR=/usr/src/linux-headers-`uname -r` -DBUILD_DRIVER=FALSE -DRADIUS=TRUE -DNETSNMP=TRUE -DSHAPER=TRUE -DLOG_PGSQL=FALSE -DLUA=TRUE -DBUILD_IPOE_DRIVER=TRUE -DBUILD_VLAN_MON_DRIVER=TRUE ../accel-ppp-code
	make
	make install
	
	cp /usr/local/src/net-snmp-5.8/mibs/* /usr/share/snmp/mibs/
	
	#dicionarios
	cp /usr/local/src/cli-ipoe/dictionary/dictionary.mikrotik /usr/share/accel-ppp/radius/
	cp /usr/local/src/cli-ipoe/dictionary/dictionary.rfc6911 /usr/share/accel-ppp/radius/
	cat /usr/local/src/cli-ipoe/dictionary/dictionary.custom >> /usr/share/accel-ppp/radius/dictionary
	

	mkdir -p /var/log/accel-ppp
	chmod -R a+rwX /var/log/accel-ppp
	chmod -R a+rwX /var/log/accel-ppp/*

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
		ipoe
	modprobe vlan_mon

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
		echo "net.netfilter.nf_conntrack_generic_timeout = 60"
		echo "net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 15"
		echo "net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 30"
		echo "net.netfilter.nf_conntrack_tcp_timeout_established = 600"
		echo "net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30"
		echo "net.netfilter.nf_conntrack_tcp_timeout_close_wait = 20"
		echo "net.netfilter.nf_conntrack_tcp_timeout_last_ack = 30"
		echo "net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30"
		echo "net.netfilter.nf_conntrack_tcp_timeout_close = 10"
		echo "net.netfilter.nf_conntrack_tcp_timeout_max_retrans = 300"
		echo "net.netfilter.nf_conntrack_tcp_timeout_unacknowledged = 300"
		echo "net.netfilter.nf_conntrack_udp_timeout = 30"
		echo "net.netfilter.nf_conntrack_udp_timeout_stream = 180"
		echo "#net.netfilter.nf_conntrack_icmpv6_timeout = 30"
		echo "net.netfilter.nf_conntrack_icmp_timeout = 10"
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
	echo "101     PBR_1"  >> /etc/iproute2/rt_tables	
	echo "102     PBR_2"  >> /etc/iproute2/rt_tables	
	echo "103     PBR_3"  >> /etc/iproute2/rt_tables	
	echo "104     PBR_4"  >> /etc/iproute2/rt_tables	

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
		echo "exit 0" 
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
	mv /usr/local/src/cli-ipoe/others/backup_to_gdrive.sh /etc/cron.daily/
   chmod +x /etc/cron.daily/backup_to_gdrive.sh
	
	

#Configurando NTP Client
#------------------------------------------------
	timedatectl set-timezone America/Sao_Paulo
	ntpdate a.ntp.br
		
	
#Google Drive Client
#------------------------------------------------
	cp /usr/local/src/cli-ipoe/others/gdrive-linux-x64 /usr/local/bin/gdrive
	chmod +x /usr/local/bin/gdrive

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

	mv /usr/local/src/cli-ipoe/clish/ /system
	mv /usr/local/src/cli-ipoe/db/ /system
	
	
	mv /usr/local/src/cli-ipoe/firewall/ /system
	chmod +x /system/firewall/firewall.sh
	ln -s /system/firewall/firewall.sh /usr/local/bin/firewall

	chmod +x /system/firewall/nftables.conf	

	mv /usr/local/src/cli-ipoe/configs/accel-ppp/ /system/configs
	mv /usr/local/src/cli-ipoe/configs/snmp/ /system/configs
	
	chmod +x /system/clish/bin/*
	
	rm -rf /etc/snmp/snmpd.conf	
	ln -s /system/configs/snmp/snmpd.conf /etc/snmp/	
	
	ln -s /system/configs/accel-ppp/* /etc/ 
	ln -s /system/clish /etc/

	mv /usr/local/src/cli-ipoe/others/net-snmp-ignore-if /sbin/
	chmod +x /sbin/net-snmp-ignore-if
	
	mv /usr/local/src/cli-ipoe/scripts /system/
	chmod +x /system/scripts/*
	
	
	


#Configurando rc.local
#------------------------------------------------	
	(
		echo '[Unit]'
		echo 'Description=/etc/rc.local'
		echo 'ConditionPathExists=/etc/rc.local'
		echo
		echo '[Service]'
		echo 'Type=forking'
		echo 'ExecStart=/etc/rc.local start'
		echo 'TimeoutSec=0'
		echo 'StandardOutput=tty'
		echo 'RemainAfterExit=yes'
		echo 'SysVStartPriority=99'
		echo
		echo '[Install]'
		echo 'WantedBy=multi-user.target'
	) > /etc/systemd/system/rc-local.service


	(
		echo '#!/bin/sh -e'
		echo
		echo 'sleep 5'
		echo "ifconfig eno1 up"
		echo "ifconfig eno2 up"
		echo '/system/scripts/irq_affinity.sh -X 0-7 eno1'
		echo '/system/scripts/irq_affinity.sh -X 8-15 eno2'
		echo '/system/scripts/ethtool.sh eno1'
		echo '/system/scripts/ethtool.sh eno2'
		echo
		echo '/system/clish/bin/pbr.sh 1 reload'
		echo '/system/firewall/firewall.sh'
		echo
		echo 'exit 0'
	) > /etc/rc.local
	
	chmod +x /etc/rc.local	
	systemctl enable rc-local
	systemctl start rc-local
	
#Outros
#------------------------------------------------
	
	echo 'export HOSTNAME=$(hostname)' >> /etc/profile	
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
	
	
	/system/clish/bin/users.sh add admin accel
	

#Banner
#------------------------------------------------

	echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config

	(
		echo "###########################################################"
		echo "#      _    ____ ____ _____ _          ____  ____  ____   #"
		echo "#     / \  / ___/ ___| ____| |        |  _ \|  _ \|  _ \  #"
		echo "#    / _ \| |  | |   |  _| | |   _____| |_) | |_) | |_) | #"
		echo "#   / ___ \ |__| |___| |___| |__|_____|  __/|  __/|  __/  #"
		echo "#  /_/   \_\____\____|_____|_____|    |_|   |_|   |_|     #"
		echo "#                                                         #"
		echo "#                                                         #"
		echo "#               Nome Provedor - JSG PPPoE 01              #"
		echo "#        Voce esta entrando em uma area restrita.         #"
		echo "#          Acesso somente a pessoas autoriadas.           #"
		echo "#         Todo acesso e monitorado e registrado!          #"
		echo "#                                                         #"
		echo "###########################################################"
	) > /etc/issue.net
	
	
	
#neofetch
#------------------------------------------------

	dpkg -i /usr/local/src/cli-ipoe/others/neofetch_6.1.0-2_all.deb

	mv /usr/local/src/cli-ipoe/others/neofetch.conf /etc/
	mv /usr/local/src/cli-ipoe/others/neofetch.logo /etc/
	
	sed -i "/PrintMotd/s/.*/PrintMotd no/"  	   /etc/ssh/sshd_config
	sed -i "/PrintLastLog/s/.*/PrintLastLog no/"  /etc/ssh/sshd_config
	
	(
		echo "#!/bin/sh"
		echo 
		echo "cat /etc/neofetch.logo"
		echo "echo"
		echo "echo"
		echo "neofetch --config /etc/neofetch.conf"
	) > /etc/update-motd.d/10-uname	

	
	
#Fim
#------------------------------------------------
	rm -rf /usr/local/src/cli-ipoe/
	clear
	echo "" > /etc/motd
	(
		echo
		echo
		echo "****************************************************************"
		echo "*                        Install Complete                      *"
		echo "****************************************************************"
		echo "*                                                              *"
		echo "*  A user was created to access SSH                            *"
		echo "*  Login....: admin                                            *"
		echo "*  Password.: accel                                            *"
		echo "*                                                              *"
		echo "*  To change the password                                      *"
		echo "*  > configure                                                 *"
		echo "*  # set system login user admin password abcxyz               *"
		echo "*                                                              *"
		echo "*  To configure Accel-PPP edit the file /etc/accel-ppp.conf    *"
		echo "*  To configure SNMP edit the file /etc/snmp/snmpd.conf        *"
		echo "*                                                              *"
		echo "****************************************************************"	
		
	)