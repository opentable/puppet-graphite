# == Class: graphite::install
#
# This class installs graphite packages via pip
#
# === Parameters
#
# None.
#
class graphite::install (
  $django_tagging_ver        = '0.4.5',
  $twisted_ver               = '13.2.0',
  $txamqp_ver                = '0.4',
  $gw_installation_type      = 'package',
  $gw_ver                    = '1.0.2',
  $gw_source                 = undef,
  $carbon_installation_type  = 'package',
  $carbon_ver                = '1.0.2',
  $carbon_source             = undef,
  $whisper_installation_type = 'package',
  $whisper_ver               = '1.0.2',
  $whisper_source            = undef,
) inherits graphite::params {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  Package {
    provider => 'pip',
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  # using the pip package provider requires python-pip

  if ! defined(Package[$::graphite::params::python_pip_pkg]) {
    package { $::graphite::params::python_pip_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  # install python headers and libs for pip

  if ! defined(Package[$::graphite::params::python_dev_pkg]) {
    package { $::graphite::params::python_dev_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  package { $::graphite::params::graphitepkgs :
    ensure   => 'installed',
    provider => undef, # default to package provider auto-discovery
  }->
  package{'django-tagging':
    ensure   => $django_tagging_ver,
  }->
  package{'twisted':
    name     => 'Twisted',
    ensure   => $twisted_ver,
  }->
  package{'txamqp':
    name     => 'txAMQP',
    ensure   => $txamqp_ver,
  }->
  class { 'graphite::install::graphite_web': } ->
  class { 'graphite::install::carbon': } ->
  class { 'graphite::install::whisper': }
}
