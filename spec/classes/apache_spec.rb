# frozen_string_literal: true

require 'spec_helper'

describe 'zend_prom_exporters::apache' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          version: '1.0.8',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_archive('apache_exporter-1.0.8.linux-amd64.tar.gz').with(
          {
            path: '/var/tmp/apache_exporter-1.0.8.linux-amd64.tar.gz',
            source: 'https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.8/apache_exporter-1.0.8.linux-amd64.tar.gz',
          },
        )
      end

      it { is_expected.to contain_systemd__manage_unit('apache_exporter.service').that_subscribes_to('Archive[apache_exporter-1.0.8.linux-amd64.tar.gz]') }

      it { is_expected.not_to contain_selinux__fcontext('apache_exporter') }

      context 'selinux enabled' do
        let(:facts) do
          os_facts.merge({ 'selinux' => { 'enabled' => true } })
        end

        it { is_expected.to contain_selinux__fcontext('apache_exporter').that_requires('Archive[apache_exporter-1.0.8.linux-amd64.tar.gz]') }
        it { is_expected.to contain_selinux__fcontext('apache_exporter').that_comes_before('Systemd::Manage_unit[apache_exporter.service]') }
      end
    end
  end
end
