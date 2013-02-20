class ipa(
	$server_ipaddr  	= ${ip_addr},
	$config_server		= true,
	$config_client  	= false,
	$dns_forwarders 	= ${forwarders},
	$password			= 'blahblahblah',
	$open_needed_ports 	= true,
	$http_tcp  			= '80/tcp',
	$https_tcp 			= '443/tcp',
	$ldap_tcp 			= '389/tcp',
	$ldaps_tcp 			= '636/tcp',
	$kerb_tcp1 			= '88/tcp',
	$kerb_tcp2 			= '464/tcp',
	$bind_tcp 			= '53/tcp',
	$kerb_udp			= '88/udp',
	$bind_udp			= '53/udp',
	$ntp				= '123/udp',
){
	if $config_server == true {
		package { ['bind', 'bind-dyndb-ldap', 'freeipa-server']:
			ensure => present
		}

		exec {'setenforce-off':
			command => "/usr/sbin/setenforce 0",
			unless => "/usr/sbin/getenforce | grep Permissive"
		}
		exec {'ipa-server-install':
			command => "/sbin/ipa-server-install -U -r `hostname | cut -d. -f 2- | tr '[:lower:]' '[:upper:]'` -p ${password} -a ${password} --setup-dns --forwarder=${dns_forwarders}",
			creates => "/etc/ipa/default.conf",
			requires => [Package['freeipa-server'], Exec['setenforce-off']]
		}

		exec {'kinit admin':
			command => "/usr/bin/echo ${password} | /usr/bin/kinit admin",
		}
	}

	if $config_client == true {
		package { ['freeipa-client', 'freeipa-admintools']:
			ensure => present
		}
		exec {'setenforce-off':
			command => "/usr/sbin/setenforce 0",
			unless => "/usr/sbin/getenforce | grep Permissive"
		}
		file {'/etc/resolv.conf':
			path => '/etc/resolv.conf',
			content => template('ipa/client/resolv.conf.erb'),
			owner => 'root',
			group => 'root',
			mode => '0644',
		}
		exec {'ipa-client-install':
			command => "/sbin/ipa-client-install --enable-dns-updates -U",
			requires => [File['/etc/resolv.conf'], Package['freeipa-client'], Exec['setenforce-off']],
			creates => "/etc/ipa/default.conf",
		}
		exec {'kinit admin':
			command => "/usr/bin/echo ${password} | /usr/bin/kinit admin",
			requires => [Package['freeipa-admintools'], Package['freeipa-client']]
		}
	}

	if $open_needed_ports == true {
		exec {'firewall-cmd1':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$http_tcp"
		}
		exec {'firewall-cmd2':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$https_tcp"
		}
		exec {'firewall-cmd3':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$ldap_tcp"
		}
		exec {'firewall-cmd4':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$ldaps_tcp"
		}
		exec {'firewall-cmd5':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$kerb_tcp1"
		}
		exec {'firewall-cmd6':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$kerb_tcp2"
		}
		exec {'firewall-cmd7':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$kerb_udp"
		}
		exec {'firewall-cmd8':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$bind_tcp"
		}
		exec {'firewall-cmd9':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$bind_udp"
		}
		exec {'firewall-cmd10':
			command => "/usr/bin/firewall-cmd --permanent --zone=public --add-port=$ntp"
		}
	}	
}