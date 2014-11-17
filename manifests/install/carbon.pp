# == Class: graphite::install::carbon
#
# This class installs carbon package via pip or from source
#
# === Parameters
#
# TODO
#
class graphite::install::carbon (
  $installation_type = $graphite::install::carbon_installation_type,
  $version           = $graphite::install::carbon_ver,
  $source            = $graphite::install::carbon_source,
) inherits graphite::params {
  validate_re($installation_type, '^(package|source)$', 'installation_type must be one of \'package\' or \'source\'')
  validate_re($version, '\d+\.\d+\.\d+(-)?\w+', 'carbon version format is incorrect')

  $carbon_pip_hack_version = regsubst($version, '-', '_')
  $carbon_pip_hack_source = "${python_pip_hack_source_path}/carbon-${carbon_pip_hack_version}-py${python_version}.egg-info"
  $carbon_pip_hack_target = "${carbon_pip_hack_target_path}/carbon-${carbon_pip_hack_version}-py${python_version}.egg-info"

  case downcase($installation_type) {
    'package': {
      package{ 'carbon':
        ensure   => $version,
        source   => $source,
        provider => pip,
        before   => File[$carbon_pip_hack_source],
        notify   => $notify_services,
      }
    }
    'source': {
      ensure_resource(file, '/var/git', {
        ensure => directory,
        mode   => '0755',
      })
      
      ensure_resource('package', 'git', { ensure => installed })

      vcsrepo { '/var/git/carbon':
        ensure   => present,
        provider => git,
        source   => $source,
        revision => $version,
        require  => File['/var/git'],
        notify   => Exec['build_carbon'],
        before   => File[$carbon_pip_hack_source],
      }

      exec { 'build_carbon':
        command     => 'python setup.py build && python setup.py install',
        cwd         => '/var/git/carbon',
        path        => $::path,
        refreshonly => true,
        notify      => $notify_services,
      }
    }
  }

  file { $carbon_pip_hack_source :
    ensure => link,
    target => $carbon_pip_hack_target,
  } ->

  exec { 'carbon_cleanup_pip_egg_info_files':
    command => "find ${python_pip_hack_source_path} -name 'carbon-*.*.*-py${python_version}.egg-info' -not -name 'carbon-${carbon_pip_hack_version}-py${python_version}.egg-info' -exec rm {} \\;",
    onlyif  => "find ${python_pip_hack_source_path} -name 'carbon-*.*.*-py${python_version}.egg-info' -not -name 'carbon-${carbon_pip_hack_version}-py${python_version}.egg-info' | egrep '.*'",
    path    => $::path,
  }
}
