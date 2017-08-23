# == Class: graphite::install::whisper
#
# This class installs whisper package via pip or from source
#
# === Parameters
#
# TODO
#
class graphite::install::whisper (
  $installation_type = $graphite::install::whisper_installation_type,
  $version           = $graphite::install::whisper_ver,
  $source            = $graphite::install::whisper_source,
) inherits graphite::params {
  validate_re($installation_type, '^(package|source)$', 'installation_type must be one of \'package\' or \'source\'')
  validate_re($version, '\d+\.\d+\.\d+(-)?\w*', 'whisper version format is incorrect')

  $whisper_pip_hack_version = regsubst($version, '-', '_')

  case downcase($installation_type) {
    'package': {
      package{ 'whisper':
        ensure   => $version,
        source   => $source,
        provider => pip,
        notify   => Exec['whisper_cleanup_pip_egg_info_files'],
      }
    }
    'source': {
      ensure_resource(file, '/var/git', {
        ensure => directory,
        mode   => '0755',
      })
      
      ensure_resource('package', 'git', { ensure => installed })

      vcsrepo { '/var/git/whisper':
        ensure   => present,
        provider => git,
        source   => $source,
        revision => $version,
        require  => File['/var/git'],
        notify   => Exec['build_whisper'],
      }

      exec { 'build_whisper':
        command     => 'python setup.py build && python setup.py install',
        cwd         => '/var/git/whisper',
        path        => $::path,
        refreshonly => true,
      }
    }
  }

  exec { 'whisper_cleanup_pip_egg_info_files':
    command     => "find /usr/local/lib/python${python_version}/${python_packages_folder} -name 'whisper-*.*.*-py${python_version}.egg-info' -not -name 'whisper-${whisper_pip_hack_version}-py${python_version}.egg-info' -exec rm {} \\;",
    onlyif      => "find /usr/local/lib/python${python_version}/${python_packages_folder} -name 'whisper-*.*.*-py${python_version}.egg-info' -not -name 'whisper-${whisper_pip_hack_version}-py${python_version}.egg-info' | egrep '.*'",
    path        => $::path,
  }
}
