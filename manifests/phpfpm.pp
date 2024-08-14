# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include zend_prom_exporters::phpfpm
class zend_prom_exporters::phpfpm (
  String          $version,
  Stdlib::HTTPUrl $release_url = "https://github.com/hipages/php-fpm_exporter/releases/download/v${version}/php-fpm_exporter_${version}_linux_amd64.tar.gz",
  Stdlib::Port    $port        = 9001,
) {
  $archive = basename($release_url)

  archive { $archive:
    ensure        => present,
    path          => "/var/tmp/${archive}",
    source        => $release_url,
    extract       => true,
    extract_flags => '--exclude LICENSE --exclude README.md -xf',
    extract_path  => '/usr/local/bin',
  } -> file { '/usr/local/bin/php-fpm_exporter':
    mode  => '0755',
    owner => 'root',
    group => 'root',
  } -> systemd::manage_unit { 'php-fpm_exporter.service':
    unit_entry    => {
      'Description' => 'PHP-FPM Prometheus Exporter',
      'Wants'       => 'network-online.target',
      'After'       => 'network-online.target',
    },
    service_entry => {
      'Type'      => 'simple',
      'ExecStart' => "/usr/local/bin/php-fpm_exporter server --phpfpm.scrape-uri tcp://127.0.0.1:8080/status --web.listen-address=\":${port}\"",
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
    enable        => true,
    active        => true,
    subscribe     => Archive[$archive],
  }

  if $facts['selinux']['enabled'] {
    selinux::fcontext { 'php-fpm_exporter':
      pathspec => '/usr/local/bin/php-fpm_exporter',
      seltype  => 'bin_t',
      filetype => 'f',
      require  => Archive[$archive],
      before   => Systemd::Manage_unit['php-fpm_exporter.service'],
    }
  }
}
