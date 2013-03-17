class ocf::local::firestorm {
  ##Heimdal server configuration##
  # if local realm has not been defined installation will fail
  package { 'heimdal-kdc':
    require => File['/etc/krb5.conf'],
  }

  #define logrotate so we can modify the conf
  package { ['logrotate']: }

  file { '/etc/logrotate.d/heimdal-kdc':
    source  => 'puppet:///modules/ocf/local/firestorm/heimdal-kdc-logrotate',
    require => Package['heimdal-kdc', 'logrotate'],
  }

  #define the heimdal service
  service { 'heimdal-kdc':
    subscribe => File['/etc/heimdal-kdc/kdc.conf', '/etc/heimdal-kdc/kadmind.acl'],
  }

  file {
    '/etc/heimdal-kdc/kdc.conf':
      source  => 'puppet:///modules/ocf/local/firestorm/kdc.conf',
      require => Package['heimdal-kdc'],
  }

  file { '/etc/heimdal-kdc/kadmind.acl':
    source  => 'puppet:///modules/ocf/local/firestorm/kadmind.acl',
    require => Package['heimdal-kdc'],
  }

  ##Ldap server install##
  #Packages
  package { ['slapd']: }

  #define service
  service { 'slapd':
    subscribe => File[ '/etc/ldap/slapd.conf', '/etc/ldap/schema/ocf.schema', '/etc/ldap/ocf_ldap.key', '/etc/default/slapd','/etc/ldap/sasl2/slapd.conf'],
  }

  #needed config files
  file {
    '/etc/ldap/slapd.conf':
      source  => 'puppet:///modules/ocf/local/firestorm/slapd.conf',
      require => Package['slapd'],
    ;
    '/etc/ldap/schema/ocf.schema':
      source  => 'puppet:///modules/ocf/local/firestorm/ocf.schema',
      require => Package['slapd'],
    ;
    '/etc/ldap/schema/puppet.schema':
      source  => 'puppet:///contrib/local/firestorm/puppet.schema',
      require => Package['slapd'],
    ;
    '/etc/ldap/ocf_ldap.key':
      source  => 'puppet:///private/ocf_ldap.key',
      require => Package['slapd', 'openssl'],
      mode    => '0600',
      owner   => 'openldap',
      group   => 'openldap',
    ;
    '/etc/default/slapd':
      source  => 'puppet:///modules/ocf/local/firestorm/slapd-defaults',
      require => Package['slapd', 'openssl'],
    ;
    '/etc/ldap/sasl2/slapd.conf':
      source  => 'puppet:///modules/ocf/local/firestorm/sasl2-slapd',
      require =>  Package['slapd', 'libsasl2-modules-gssapi-mit'],
    ;
    '/etc/ldap/krb5.keytab':
      source  => 'puppet:///private/krb5-ldap.keytab',
      require => Package['slapd', 'heimdal-clients'],
      mode    => '0600',
      owner   => 'openldap',
      group   => 'openldap',
    ;
  }

  # LDAP revision control
  # ldap-git-backup currently must be fetched from unstable
  package { 'ldap-git-backup': }
  file {
    # Snapshot daily at 4AM
    '/etc/cron.d/ldap-git-backup':
      content => '0 4 * * * root /usr/sbin/ldap-git-backup',
      require => Package['ldap-git-backup'],
    ;
    # Push repository to GitHub
    '/var/backups/ldap/.git/hooks/post-commit':
      mode    => '0755',
      content => 'git push -fq git@github.com:ocf/ldap',
      require => [Package['ldap-git-backup'], File['/root/.ssh/id_rsa']],
    ;
    '/root/.ssh':
      ensure  => directory,
      mode    => '0600',
    ;
    # GitHub deployer key
    '/root/.ssh/id_rsa':
      mode   => '0600',
      source => 'puppet:///private/id_rsa',
    ;
  }

}
