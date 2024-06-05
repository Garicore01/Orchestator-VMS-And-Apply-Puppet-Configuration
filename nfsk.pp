class nfsk {
  $domain = '1.5.ff.es.eu.org'
  $hostname = $facts['networking']['hostname']
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

  exec { 'ipa_client_automount':
    command => "echo 'y' | sudo ipa-client-automount --location=default",
    path    => "/usr/bin",
  }
}

class { 'nfsk': }
