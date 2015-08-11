# Package installation
class ossec::common {
  case $::osfamily {
    'Debian' : {
      $hidsagentservice  = 'ossec'
      $hidsagentpackage  = 'ossec-hids-agent'
      $servicehasstatus  = false

      case $::lsbdistcodename {
        /(lucid|precise|trusty)/: {
          $hidsserverservice = 'ossec-hids-server'
          $hidsserverpackage = 'ossec-hids-server'
          apt::ppa { 'ppa:nicolas-zin/ossec-ubuntu': }
        }
        /^(jessie|wheezy)$/: {
          $hidsserverservice = 'ossec'
          $hidsserverpackage = 'ossec-hids'

          apt::source { 'alienvault':
            ensure      => present,
            comment     => 'This is the AlienVault Debian repository for Ossec',
            location    => 'http://ossec.alienvault.com/repos/apt/debian',
            release     => $::lsbdistcodename,
            repos       => 'main',
            include_src => false,
            include_deb => true,
            key         => '9A1B1C65',
            key_source  => 'http://ossec.alienvault.com/repos/apt/conf/ossec-key.gpg.key',
          }
          exec { 'update-apt-alienvault-repo':
            command     => '/usr/bin/apt-get update',
            refreshonly => true
          }
        }
        default: { fail('This ossec module has not been tested on your distribution (or lsb package not installed)') }
      }
    }
    'Redhat' : {
      # Set up OSSEC rpm gpg key
      file { 'RPM-GPG-KEY.ossec.txt':
        path   => '/etc/pki/rpm-gpg/RPM-GPG-KEY.ossec.txt',
        source => 'puppet:///modules/ossec/RPM-GPG-KEY.ossec.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0664',
      }

      # Set up OSSEC repo
      if( $releasever == "7Server" ) {
        $local_releasever = "7"
      } else {
        $local_releasever = $releasever
      }
      yumrepo { 'ossec':
        descr      => 'CentOS / Red Hat Enterprise Linux $releasever - ossec.net',
        enabled    => true,
        gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY.ossec.txt',
        mirrorlist => 'http://updates.atomicorp.com/channels/mirrorlist/ossec/centos-$local_releasever-$basearch',
        priority   => 1,
        protect    => false,
      }

      # Set up EPEL repo
      #include epel
#      if $::operatingsystemmajrelease {
#        $os_maj_release = $::operatingsystemmajrelease
#      } else {
#        $os_versions    = split($::operatingsystemrelease, '[.]')
#        $os_maj_release = $os_versions[0]
#      }

#      $epel_mirrorlist                        = "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${os_maj_release}&arch=\$basearch"
#      $epel_baseurl                           = 'absent'
#      $epel_failovermethod                    = 'priority'
#      $epel_proxy                             = 'absent'
#      $epel_enabled                           = '1'
#      $epel_gpgcheck                          = '1'

#      yumrepo { 'epel':
#        mirrorlist     => $epel_mirrorlist,
#        baseurl        => $epel_baseurl,
#        failovermethod => $epel_failovermethod,
#        proxy          => $epel_proxy,
#        enabled        => $epel_enabled,
#        gpgcheck       => $epel_gpgcheck,
##        gpgkey         => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${os_maj_release}",
#        gpgkey         => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-${os_maj_release}",
#        descr          => "Extra Packages for Enterprise Linux ${os_maj_release} - \$basearch",
#      }


      $hidsagentservice  = 'ossec-hids'
      $hidsagentpackage  = 'ossec-hids-client'
      $hidsserverservice = 'ossec-hids'
      $hidsserverpackage = 'ossec-hids-server'
      $servicehasstatus  = true
      case $::operatingsystemrelease {
        /^5/:    {$redhatversion='el5'}
        /^6/:    {$redhatversion='el6'}
        /^7/:    {$redhatversion='el7'}
        default: { }
      }
      package { 'inotify-tools':
        ensure  => present,
        require => Yumrepo["epel"],
      }
    }
    default: { fail('This ossec module has not been tested on your distribution') }
  }
}
