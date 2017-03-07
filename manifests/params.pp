# == Class: graphite::params
#
# This class specifies default parameters for the graphite module and
# SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::params {
  $build_dir = '/usr/local/src/'

  $python_pip_pkg = 'python-pip'
  # $graphiteVersion = '0.9.12'
  # $carbonVersion   = '0.9.12'
  # $whisperVersion  = '0.9.12'

  # $whisper_dl_url = "http://github.com/graphite-project/whisper/archive/${::graphite::params::whisperVersion}.tar.gz"
  # $whisper_dl_loc = "${build_dir}/whisper-${::graphite::params::whisperVersion}"
  #
  # $webapp_dl_url = "http://github.com/graphite-project/graphite-web/archive/${::graphite::params::graphiteVersion}.tar.gz"
  # $webapp_dl_loc = "${build_dir}/graphite-web-${::graphite::params::graphiteVersion}"

  # $carbon_dl_url = "https://github.com/graphite-project/carbon/archive/${carbonVersion}.tar.gz"
  # $carbon_dl_loc = "${build_dir}/carbon-${carbonVersion}"

  $install_prefix = '/opt/'
  $enable_carbon_relay = false
  $nginxconf_dir = '/etc/nginx/sites-available'


  case $::osfamily {
    'debian': {
      $apache_pkg = 'apache2'
      $apache_wsgi_pkg = 'libapache2-mod-wsgi'
      $apache_wsgi_socket_prefix = '/var/run/apache2/wsgi'
      $apache_service_name = 'apache2'
      $apacheconf_dir = '/etc/apache2/sites-available'
      $apacheports_file = 'ports.conf'
      $apache_dir = '/etc/apache2'
      if "$graphite::gr_web_group" != ""
      {
        $web_group = $graphite::gr_web_group
      }
      else
      {
        $web_group = 'www-data'
      }
      if "$graphite::gr_web_user" != ""
      {
        $web_user = $graphite::gr_web_user
      }
      else
      {
        $web_user = 'www-data'
      }
      $python_dev_pkg = 'python-dev'

      # see https://github.com/graphite-project/carbon/issues/86
      $python_version = '2.7'
      $python_packages_folder = 'dist-packages'
      $python_pip_hack_source_path = "/usr/lib/python${python_version}/${python_packages_folder}"
      $carbon_pip_hack_target_path = "/opt/graphite/lib"
      $gweb_pip_hack_target_path = "/opt/graphite/webapp"

      $graphitepkgs = [
        'python-cairo',
        'python-twisted',
        'python-django',
        'python-ldap',
        'python-memcache',
        'python-sqlite',
        'python-simplejson',
        'python-mysqldb',
        'python-psycopg2'
      ]
    }
    'redhat': {
      $apache_pkg = 'httpd'
      $apache_wsgi_pkg = 'mod_wsgi'
      $apache_wsgi_socket_prefix = 'run/wsgi'
      $apache_service_name = 'httpd'
      $apacheconf_dir = '/etc/httpd/conf.d'
      $apacheports_file = 'graphite_ports.conf'
      $apache_dir = '/etc/httpd'
      if "$graphite::gr_web_group" != ""
      {
        $web_group = $graphite::gr_web_group
      }
      else
      {
        $web_group = 'apache'
      }
      if "$graphite::gr_web_user" != ""
      {
        $web_user = $graphite::gr_web_user
      }
      else
      {
        $web_user = 'apache'
      }
      $python_dev_pkg = 'python-devel'

      # see https://github.com/graphite-project/carbon/issues/86
      case $::operatingsystemrelease {
        /^6\.\d+$/: {
          $python_version = "2.6"
        }
        /^7\.\d+/: {
          $python_version = "2.7"
        }
        default: {fail('Unsupported Redhat release')}
      }

      $python_packages_folder = 'site-packages'
      $python_pip_hack_source_path = "/usr/lib/python${python_version}/${python_packages_folder}"
      $carbon_pip_hack_target_path = "/opt/graphite/lib"
      $gweb_pip_hack_target_path = "/opt/graphite/webapp"

      $graphitepkgs = [
        'pycairo',
        'Django14',
        'python-ldap',
        'python-memcached',
        'python-sqlite2',
        'bitmap',
        'bitmap-fonts-compat',
        'python-crypto',
        'pyOpenSSL',
        'gcc',
        'python-zope-interface',
        'MySQL-python',
        'python-psycopg2'
      ]
    }
    default: {fail('unsupported os.')}
  }

  $web_server_pkg = $graphite::gr_web_server ? {
    apache      => $apache_pkg,
    nginx       => 'nginx',
    nginx_uwsgi => 'nginx',
    wsgionly    => 'dont-install-webserver-package',
    none        => 'dont-install-webserver-package',
    default     => fail('The only supported web servers are \'apache\', \'nginx_uwsgi\', \'nginx\',  \'wsgionly\' and \'none\''),
  }

  # configure carbon engines
  if $::graphite::gr_enable_carbon_relay and $::graphite::gr_enable_carbon_aggregator {
    $notify_services = [
      Service['carbon-aggregator'],
      Service['carbon-relay'],
      Service['carbon-cache']
    ]
  }
  elsif $::graphite::gr_enable_carbon_relay {
    $notify_services = [
      Service['carbon-relay'],
      Service['carbon-cache']
    ]
  }
  elsif $::graphite::gr_enable_carbon_aggregator {
    $notify_services = [
      Service['carbon-aggregator'],
      Service['carbon-cache']
    ]
  }
  else {
    $notify_services = [ Service['carbon-cache'] ]
  }
}
