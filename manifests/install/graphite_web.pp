# == Class: graphite::install::graphite_web
#
# This class installs graphite-web package via pip or from source
#
# === Parameters
#
# TODO
#
class graphite::install::graphite_web (
  $installation_type = $graphite::install::gw_installation_type,
  $version           = $graphite::install::gw_ver,
  $source            = $graphite::install::gw_source,
) inherits graphite::params {
  validate_re($installation_type, '^(package|source)$', 'installation_type must be one of \'package\' or \'source\'')
  validate_re($version, '\d+\.\d+\.\d+(-)?\w*', 'graphite-web version format is incorrect')

  $gweb_pip_hack_version = regsubst($version, '-', '_')
  $gweb_pip_hack_source = "${python_pip_hack_source_path}/graphite_web-${gweb_pip_hack_version}-py${python_version}.egg-info"
  $gweb_pip_hack_target = "${gweb_pip_hack_target_path}/graphite_web-${gweb_pip_hack_version}-py${python_version}.egg-info"

  case downcase($installation_type) {
    'package': {
      package{ 'graphite-web':
        ensure   => $version,
        source   => $source,
        provider => pip,
        before   => File[$gweb_pip_hack_source],
        notify   => $notify_services,
      }
    }
    'source': {
      ensure_resource('package', 'git', { ensure => installed })

      ensure_resource(file, '/var/git', {
        ensure => directory,
        mode   => '0755',
      })

      exec { "clean graphite-web repo":
        command     => '/bin/rm -rf ./graphite-web',
        cwd         => '/var/git/',
        path        => $::path,
        onlyif => "test -d /var/git/graphite-web",
        unless  => "/usr/bin/pip list | grep graphite-web | grep ${version}",
      } ->

      vcsrepo { "/var/git/graphite-web":
        ensure   => present,
        provider => git,
        source   => $source,
        revision => $version,
        require  => File['/var/git'],
        notify   => Exec['build_graphite-web'],
        before   => File[$gweb_pip_hack_source],
      }

      exec { 'build_graphite-web':
        command     => 'python setup.py build && python setup.py install',
        cwd         => "/var/git/graphite-web",
        path        => $::path,
        refreshonly => true,
        notify      => $notify_services,
      }

    }
  } ->

  file { $gweb_pip_hack_source :
    ensure => link,
    target => $gweb_pip_hack_target,
  } ->

  exec { 'gweb_cleanup_pip_egg_info_files':
    command => "find ${python_pip_hack_source_path} -name 'graphite_web-*.*.*-py${python_version}.egg-info' -not -name 'graphite_web-${gweb_pip_hack_version}-py${python_version}.egg-info' -exec rm {} \\;",
    onlyif  => "find ${python_pip_hack_source_path} -name 'graphite_web-*.*.*-py${python_version}.egg-info' -not -name 'graphite_web-${gweb_pip_hack_version}-py${python_version}.egg-info' | egrep '.*'",
    path    => $::path,
  } ->

  file { '/opt/graphite/webapp/graphite/manage.py':
    ensure => present,
    source => "/var/git/graphite-web/webapp/manage.py",
    require      => File[$gweb_pip_hack_source],
  } ->

  file { '/opt/graphite/static':
    ensure  => directory,
  } ->

  exec { 'build_static_assets':
    command     => 'django-admin collectstatic --noinput --settings=graphite.settings',
    cwd         => '/opt/graphite',
    environment => [ "PYTHONPATH=$PYTHONPATH:/opt/graphite/webapp" ],
    path        => $::path,
    subscribe   => File['/opt/graphite/static'],
    refreshonly => true,
    notify      => ::Graphite::Service['uwsgi'],
  }
}
