# == Class: graphite::config_uwsgi
#
# This class configures graphite/carbon/whisper and SHOULD NOT be
# called directly.
#
# === Parameters
#
# None.
#
class graphite::config_uwsgi inherits graphite::params {

  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  if $::osfamily == 'debian' {

    package {
      'uwsgi':
        ensure => installed,
        before => Exec['Chown graphite for web user'],
        notify => Exec['Chown graphite for web user'];
    }->
    package {
      'uwsgi-plugin-python':
        ensure => installed,
    }

    # Deploy configfiles
    file {
      '/etc/uwsgi':
        ensure => directory,
        mode   => '0755',
    } ->
    file {
      '/etc/uwsgi/apps-available':
        ensure => directory,
        mode   => '0755',
    } ->
    file {
      '/etc/uwsgi/apps-enabled':
        ensure => directory,
        mode   => '0755',
    } ->
    file {
      '/etc/uwsgi/apps-available/graphite.ini':
        ensure  => file,
        mode    => '0755',
        require => Package['uwsgi'],
        notify  => Service['uwsgi'],
        content => template('graphite/etc/uwsgi/apps-available/graphite.erb'),
    } ->
    file {
      '/etc/uwsgi/apps-enabled/graphite.ini':
        ensure => 'link',
        target => '/etc/uwsgi/apps-available/graphite.ini'
    } ->
    file {
      '/opt/graphite/conf/wsgi.py':
        ensure => 'link',
        target => '/opt/graphite/conf/graphite.wsgi'
    } ->
    service {
      'uwsgi':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => false,
        subscribe  => File['/opt/graphite/webapp/graphite/local_settings.py'],
        require    => [
          Package['uwsgi'],
          Exec['Initial django db creation'],
          Exec['Chown graphite for web user']
        ];
    }

  } else {
    fail("uwsgi-based graphite is not supported on ${::operatingsystem} (only supported on Debian)")
  }

}
