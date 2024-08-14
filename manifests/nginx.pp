# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include zend_prom_exporters::nginx
class zend_prom_exporters::nginx (
  Stdlib::Port $port = 9113,
) {
  include snap

  $snappath = $facts['os']['family'] ? {
    'RedHat' => '/var/lib/snapd/snap',
    'debian' => '/snap',
  }

  package { 'nginx-prometheus-exporter':
    ensure   => installed,
    provider => 'snap',
  } ~> systemd::manage_unit { 'nginx_exporter.service':
    unit_entry    => {
      'Description' => 'Nginx Prometheus Exporter',
      'Wants'       => 'network-online.target',
      'After'       => 'network-online.target',
    },
    service_entry => {
      'Type'      => 'simple',
      'ExecStart' => "${snappath}/bin/nginx-prometheus-exporter --nginx.scrape-uri=http://127.0.0.1:8080/stub_status --web.listen-address=:${port}",
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
    enable        => true,
    active        => true,
  }

  if $facts['selinux']['enabled'] {
    selinux::fcontext { 'nginx_exporter':
      pathspec => "${snappath}/bin/nginx_exporter",
      seltype  => 'bin_t',
      filetype => 'f',
      require  => Package['nginx-prometheus-exporter'],
      before   => Systemd::Manage_unit['nginx_exporter.service'],
    }
  }
}
