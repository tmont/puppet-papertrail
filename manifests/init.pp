# == Class: papertrail
#
# See README.md
#
class papertrail (
  $log_port               = '',
  $log_host               = 'logs.papertrailapp.com',
  $papertrail_certificate = 'puppet:///modules/papertrail/papertrail.crt',
  $extra_logs             = [],
  $template               = 'papertrail/rsyslog.conf.erb',
  $rate_limit_interval    = 5,
  $rate_limit_burst       = 200
) {
  file { 'rsyslog papertrail config':
    ensure   => file,
    content  => template($template),
    path     => '/etc/rsyslog.d/99-papertrail.conf',
    notify   => Service['rsyslog'],
  }

  package { 'rsyslog-gnutls':
    ensure => installed,
    notify => Service['rsyslog'],
  }

  package { 'libssl-dev':
    ensure => present,
  }

  service { 'rsyslog':
    ensure => running,
  }

  file { 'papertrail certificate':
    ensure => file,
    source => $papertrail_certificate,
    path   => '/etc/papertrail.crt',
    notify => Service['rsyslog'],
  }

  package { 'remote_syslog':
    ensure   => present,
    provider => 'gem',
    require  => [
      Package['libssl-dev'],
    ],
  }

  file { 'remote_syslog upstart script':
    ensure => file,
    source => 'puppet:///modules/papertrail/remote_syslog.upstart.conf',
    path   => '/etc/init/remote_syslog.conf',
  }

  $remote_syslog_status = empty($extra_logs) ? {
    true => stopped,
    false  => running
  }

  $remote_syslog_file = empty($extra_logs) ? {
    true => absent,
    false  => file
  }

  file { 'remote_syslog config':
    ensure  => $remote_syslog_file,
    content => template('papertrail/log_files.yml.erb'),
    path    => '/etc/log_files.yml',
    require => File['remote_syslog upstart script'],
    notify  => Service['remote_syslog'],
  }

  service { 'remote_syslog':
    ensure      => $remote_syslog_status,
    provider    => 'upstart',
    require     => File['remote_syslog upstart script'],
  }
}
