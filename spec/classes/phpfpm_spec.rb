# frozen_string_literal: true

require 'spec_helper'

describe 'zend_prom_exporters::phpfpm' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          version: '2.2.0',
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_archive('php-fpm_exporter_2.2.0_linux_amd64.tar.gz').with(
          {
            path: '/var/tmp/php-fpm_exporter_2.2.0_linux_amd64.tar.gz',
            source: 'https://github.com/hipages/php-fpm_exporter/releases/download/v2.2.0/php-fpm_exporter_2.2.0_linux_amd64.tar.gz',
          },
        )
      end

      it { is_expected.to contain_systemd__manage_unit('php-fpm_exporter.service').that_subscribes_to('Archive[php-fpm_exporter_2.2.0_linux_amd64.tar.gz]') }

      it { is_expected.not_to contain_selinux__fcontext('php-fpm_exporter') }

      context 'selinux enabled' do
        let(:facts) do
          os_facts.merge({ 'selinux' => { 'enabled' => true } })
        end

        it { is_expected.to contain_selinux__fcontext('php-fpm_exporter').that_requires('Archive[php-fpm_exporter_2.2.0_linux_amd64.tar.gz]') }
        it { is_expected.to contain_selinux__fcontext('php-fpm_exporter').that_comes_before('Systemd::Manage_unit[php-fpm_exporter.service]') }
      end
    end
  end
end
