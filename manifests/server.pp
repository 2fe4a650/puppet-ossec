# Main ossec server config
class ossec::server (
  $mailserver_ip,
  $ossec_emailto,
  $ossec_emailfrom                     = "ossec@${::domain}",
  $ossec_active_response               = true,
  $ossec_rootcheck                     = true,
  $ossec_global_host_information_level = 8,
  $ossec_global_stat_level             = 8,
  $ossec_email_alert_level             = 7,
  $ossec_ignorepaths                   = [],
  $ossec_emailnotification             = 'yes',
  $ossec_windows_ruleset               = false,
  $ossec_mysql                         = false,
) {
  include ossec::common

  # install package
  case $::osfamily {
    'Debian' : {
      package { $ossec::common::hidsserverpackage:
        ensure  => installed,
        require => Apt::Source['alienvault'],
      }
    }
    'RedHat' : {
      case $::operatingsystem {
        'CentOS' : {
          case $::operatingsystemmajrelease {
            '7' : {
              if ( $ossec_mysql  == true ) {
                package { 'mariadb': ensure => present }
                package { 'ossec-hids':
                  ensure   => installed,
                }
                package { $ossec::common::hidsserverpackage:
                  ensure  => installed,
                  require => Package['mariadb'],
                }
              } else {
                package { 'ossec-hids':
                  ensure   => installed,
                }
                package { $ossec::common::hidsserverpackage:
                  ensure  => installed,
                }
              }
            }
            default: {
              if ( $ossec_mysql  == true ) {
                package { 'mysql': ensure => present }
                package { 'ossec-hids':
                  ensure   => installed,
                }
                package { $ossec::common::hidsserverpackage:
                  ensure  => installed,
                  require => Package['mysql'],
                }
              } else {
                package { 'ossec-hids':
                  ensure   => installed,
                }
                package { $ossec::common::hidsserverpackage:
                  ensure  => installed,
                }
              }
            }
          }
        }
        'RedHat' : {
          package { $ossec::common::hidsserverpackage:
            ensure  => installed,
            require => Package['mysql'],
          }
          package { 'mysql': ensure => present }
          package { 'ossec-hids':
            ensure   => installed,
          }
          package { $ossec::common::hidsserverpackage:
            ensure  => installed,
            require => Package['mysql'],
          }
        }
      }
    }
    default: { fail('OS family not supported') }
  }

  service { $ossec::common::hidsserverservice:
    ensure    => running,
    enable    => true,
    hasstatus => $ossec::common::servicehasstatus,
    pattern   => $ossec::common::hidsserverservice,
    require   => Package[$ossec::common::hidsserverpackage],
  }

  # configure ossec
  concat { '/var/ossec/etc/ossec.conf':
    owner   => 'root',
    group   => 'ossec',
    mode    => '0440',
    require => Package[$ossec::common::hidsserverpackage],
    notify  => Service[$ossec::common::hidsserverservice]
  }
  concat::fragment { 'ossec.conf_10' :
    target  => '/var/ossec/etc/ossec.conf',
    content => template('ossec/10_ossec.conf.erb'),
    order   => 10,
    notify  => Service[$ossec::common::hidsserverservice]
  }
  concat::fragment { 'ossec.conf_90' :
    target  => '/var/ossec/etc/ossec.conf',
    content => template('ossec/90_ossec.conf.erb'),
    order   => 90,
    notify  => Service[$ossec::common::hidsserverservice]
  }

  concat { '/var/ossec/etc/client.keys':
    owner   => 'root',
    group   => 'ossec',
    mode    => '0640',
    notify  => Service[$ossec::common::hidsserverservice],
    require => Package[$ossec::common::hidsserverpackage],
  }
  concat::fragment { 'var_ossec_etc_client.keys_end' :
    target  => '/var/ossec/etc/client.keys',
    order   => 99,
    content => "\n",
    notify  => Service[$ossec::common::hidsserverservice]
  }
  Ossec::Agentkey<<| |>>

  if ( $ossec_windows_ruleset  == true ) {
    # Include Windows registry rules
    concat { '/var/ossec/rules/local_rules.xml':
      owner   => 'root',
      group   => 'ossec',
      mode    => '0644',
      require => Package[$ossec::common::hidsserverpackage],
      notify  => Service[$ossec::common::hidsserverservice]
    }
    concat::fragment { 'local_rules.xml_10' :
      target  => '/var/ossec/rules/local_rules.xml',
      content => template('ossec/local_rules.xml.erb'),
      order   => 10,
      notify  => Service[$ossec::common::hidsserverservice]
    }
  }

}
