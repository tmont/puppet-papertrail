class papertrail (
	$log_port,
	$log_host = 'logs.papertrailapp.com',
	$template = 'papertrail/rsyslog.conf.erb',
	$papertrail_certificate = 'puppet:///modules/papertrail/papertrail.crt',
	$extra_logs = [],
) {

	file { 'rsyslog config':
		ensure  => file,
		content  => template($template),
		path    => '/etc/rsyslog.d/99-papertrail.conf',
		notify  => Service['rsyslog'],
	}

	package { 'rsyslog-gnutls':
		ensure => installed,
		notify => Service['rsyslog'],
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

	package { 'gcc':
		ensure => present,
	}

	package { 'rubygems':
		ensure => present,
	}

	package { 'libssl-dev':
		ensure => present,
	}

	package { 'remote_syslog':
		ensure => present,
		provider => 'gem',
		require => [
			Package['rubygems'],
			Package['gcc'],
			Package['libssl-dev'],
		],
	}

	file { 'remote_syslog upstart script':
		ensure => file,
		source => 'puppet:///modules/papertrail/remote_syslog.upstart.conf',
		path => '/etc/init/remote_syslog.conf',
	}

	service { 'remote_syslog':
		ensure => running,
		require => File['remote_syslog upstart script'],
	}

	file { 'remote_syslog config':
		content => template('papertrail/log_files.yml.erb'),
		path => '/etc/log_files.yml',
		ensure => file,
		require => File['remote_syslog upstart script'],
		notify => Service['remote_syslog'],
	}
}