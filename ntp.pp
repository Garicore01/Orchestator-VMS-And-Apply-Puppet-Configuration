# Instalar el paquete chrony
class ntp {
  # Instalar el paquete chrony
  package { 'chrony':
    ensure => installed,
  }

  # Definir la configuración del servicio chronyd
  file { '/etc/chrony.conf':
    ensure  => file,
    content => template('/tmp/chrony.conf.erb'),
    notify  => Service['chronyd'],
  }

  # Iniciar y habilitar el servicio chronyd
  service { 'chronyd':
    ensure => running,
    enable => true,
  }
}

class { 'ntp': }