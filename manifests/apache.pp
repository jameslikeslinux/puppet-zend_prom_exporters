# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include zend_prom_exporters::apache
class zend_prom_exporters::apache (
  String          $version,
  Stdlib::HTTPUrl $release_url = "https://github.com/Lusitaniae/apache_exporter/releases/download/v${version}/apache_exporter-${version}.linux-amd64.tar.gz",
  Stdlib::Port    $port        = 9117,
) {
  $archive = basename($release_url)

  $user = $facts['os']['family'] ? {
    'RedHat' => 'apache',
    'debian' => 'www-data',
  }

  archive { $archive:
    ensure        => present,
    path          => "/var/tmp/${archive}",
    source        => $release_url,
    extract       => true,
    extract_flags => '--exclude LICENSE --strip-components=1 -xf',
    extract_path  => '/usr/local/bin',
  } -> file { '/usr/local/bin/apache_exporter':
    mode  => '0755',
    owner => 'root',
    group => 'root',
  } -> systemd::manage_unit { 'apache_exporter.service':
    unit_entry    => {
      'Description' => 'Apache Prometheus Exporter',
      'Wants'       => 'network-online.target',
      'After'       => 'network-online.target',
    },
    service_entry => {
      'User'      => $user,
      'Group'     => $user,
      'Type'      => 'simple',
      'ExecStart' => "/usr/local/bin/apache_exporter --insecure --scrape_uri=http://localhost/server-status/?auto --telemetry.endpoint=/metrics --web.listen-address=:${port}",
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
    enable        => true,
    active        => true,
    subscribe     => Archive[$archive],
  }

  if $facts['selinux']['enabled'] {
    selinux::fcontext { 'apache_exporter':
      pathspec => '/usr/local/bin/apache_exporter',
      seltype  => 'bin_t',
      filetype => 'f',
      require  => Archive[$archive],
      before   => Systemd::Manage_unit['apache_exporter.service'],
    }
  }
}
