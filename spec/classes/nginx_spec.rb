# frozen_string_literal: true

require 'spec_helper'

describe 'zend_prom_exporters::nginx' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('snap') }

      it { is_expected.to contain_package('nginx-prometheus-exporter').with_provider('snap') }

      it { is_expected.to contain_systemd__manage_unit('nginx_exporter.service').that_subscribes_to('Package[nginx-prometheus-exporter]') }

      it { is_expected.not_to contain_selinux__fcontext('nginx_exporter') }

      context 'selinux enabled' do
        let(:facts) do
          os_facts.merge({ 'selinux' => { 'enabled' => true } })
        end

        it { is_expected.to contain_selinux__fcontext('nginx_exporter').that_requires('Package[nginx-prometheus-exporter]') }
        it { is_expected.to contain_selinux__fcontext('nginx_exporter').that_comes_before('Systemd::Manage_unit[nginx_exporter.service]') }
      end
    end
  end
end
