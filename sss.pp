class sss {
  $domain = '1.5.ff.es.eu.org'
  $realm = '1.5.FF.ES.EU.ORG'
  $server = 'ipa1.1.5.ff.es.eu.org'
  $hostname = $facts['networking']['hostname']
  $ipa_master_ip = 'ip_master_ip_address'
  $ntp_server_1_ip = 'ntp1_ip_address'
  $ntp_server_2_ip = 'ntp2_ip_address'
  $password = 'Welcome1.'
  $ip_address = $facts['networking']['ip6']

  file { '/etc/hostname':
    ensure  => present,
    content => "${hostname}.${domain}\n",
  }

  host { $hostname:
    ensure => present,
    name => "${hostname}.${domain}",
    host_aliases => [$hostname],
    ip => "${ip_address}",
  }

  host { 'ipa1':
    ensure => present,
    name => "ipa1.1.5.ff.es.eu.org",
    host_aliases => "ipa1",
    ip => "2001:470:736b:511::2",  
  }

  host { 'ipa2':
    ensure => present,
    name => "ipa2.1.5.ff.es.eu.org",
    host_aliases => "ipa2",
    ip => "2001:470:736b:511::3", 
  }


  file { '/etc/hosts':
    ensure  => present,
    require => Host[$hostname, 'ipa1', 'ipa2'],
  }

  package { 'freeipa-client':
    ensure => installed,
  }

  service { 'sssd':
    ensure => running,
    enable => true,
    require => Package['freeipa-client'],
  }

  exec { 'join_freeipa_domain':
    command => "sudo ipa-client-install --server=$server --domain=$domain --ip-address=$ip_address --realm=$realm --ntp-server=$ntp_server_1_ip --ntp-server=$ntp_server_2_ip --password=$password --principal=admin@1.5.FF.ES.EU.ORG --unattended",
    path => "/usr/bin",
    require => Package['freeipa-client'],
  }
}

class { 'sss': }
