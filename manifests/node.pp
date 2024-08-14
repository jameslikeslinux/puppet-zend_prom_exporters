# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include zend_prom_exporters::node
class zend_prom_exporters::node (
  String          $version,
  Stdlib::HTTPUrl $release_url = "https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-amd64.tar.gz",
  Stdlib::Port    $port        = 9100,
) {
  $archive = basename($release_url)

  user { 'node_exporter':
    ensure => present,
    shell  => '/bin/false',
    system => true,
  }

  archive { $archive:
    ensure        => present,
    path          => "/var/tmp/${archive}",
    source        => $release_url,
    extract       => true,
    extract_flags => '--exclude LICENSE --exclude NOTICE --strip-components=1 -xf',
    extract_path  => '/usr/local/bin',
  } -> file { '/usr/local/bin/node_exporter':
    mode  => '0755',
    owner => 'root',
    group => 'root',
  } -> systemd::manage_unit { 'node_exporter.service':
    unit_entry    => {
      'Description' => 'Node Prometheus Exporter',
      'Wants'       => 'network-online.target',
      'After'       => 'network-online.target',
    },
    service_entry => {
      'User'      => 'node_exporter',
      'Group'     => 'node_exporter',
      'Type'      => 'simple',
      'ExecStart' => "/usr/local/bin/node_exporter --web.listen-address=:${port}",
    },
    install_entry => {
      'WantedBy' => 'multi-user.target',
    },
    enable        => true,
    active        => true,
    require       => User['node_exporter'],
    subscribe     => Archive[$archive],
  }

  if $facts['selinux']['enabled'] {
    selinux::fcontext { 'node_exporter':
      pathspec => '/usr/local/bin/node_exporter',
      seltype  => 'bin_t',
      filetype => 'f',
      require  => Archive[$archive],
      before   => Systemd::Manage_unit['node_exporter.service'],
    }
  }
}
