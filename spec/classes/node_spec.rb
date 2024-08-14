# frozen_string_literal: true

require 'spec_helper'

describe 'zend_prom_exporters::node' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          version: '1.8.2',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_user('node_exporter').with(
          {
            shell: '/bin/false',
            system: true,
          },
        )
      end

      it do
        is_expected.to contain_archive('node_exporter-1.8.2.linux-amd64.tar.gz').with(
          {
            path: '/var/tmp/node_exporter-1.8.2.linux-amd64.tar.gz',
            source: 'https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz',
          },
        )
      end

      it { is_expected.to contain_systemd__manage_unit('node_exporter.service').that_subscribes_to('Archive[node_exporter-1.8.2.linux-amd64.tar.gz]') }

      it { is_expected.not_to contain_selinux__fcontext('node_exporter') }

      context 'selinux enabled' do
        let(:facts) do
          os_facts.merge({ 'selinux' => { 'enabled' => true } })
        end

        it { is_expected.to contain_selinux__fcontext('node_exporter').that_requires('Archive[node_exporter-1.8.2.linux-amd64.tar.gz]') }
        it { is_expected.to contain_selinux__fcontext('node_exporter').that_comes_before('Systemd::Manage_unit[node_exporter.service]') }
      end
    end
  end
end
