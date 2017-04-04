#
# Copyright 2017 Fujitsu LIMITED
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module MonascaHelper
  class << self
    def monasca_public_host(node)
      ha_enabled = node[:monasca][:ha][:enabled]
      ssl_enabled = node[:monasca][:api][:ssl]
      CrowbarHelper.get_host_for_public_url(node, ssl_enabled, ha_enabled)
    end

    def monasca_admin_host(node)
      ha_enabled = node[:monasca][:ha][:enabled]
      CrowbarHelper.get_host_for_admin_url(node, ha_enabled)
    end

    def api_public_url(node)
      host = monasca_public_host(node)
      # SSL is not supported at this moment
      # protocol = node[:monasca][:api][:ssl] ? "https" : "http"
      protocol = "http"
      port = node[:monasca][:api][:bind_port]
      "#{protocol}://#{host}:#{port}/v2.0"
    end

    def api_admin_url(node)
      host = monasca_admin_host(node)
      # SSL is not supported at this moment
      # protocol = node[:monasca][:api][:ssl] ? "https" : "http"
      protocol = "http"
      port = node[:monasca][:api][:bind_port]
      "#{protocol}://#{host}:#{port}/v2.0"
    end

    def api_internal_url(node)
      host = get_host_for_monitoring_url(node)
      # SSL is not supported at this moment
      # protocol = node[:monasca][:api][:ssl] ? "https" : "http"
      protocol = "http"
      port = node[:monasca][:api][:bind_port]
      "#{protocol}://#{host}:#{port}/v2.0"
    end

    def log_api_public_url(node)
      host = monasca_public_host(node)
      # SSL is not supported at this moment
      # protocol = node[:monasca][:log_api][:ssl] ? "https" : "http"
      protocol = "http"
      port = node[:monasca][:log_api][:bind_port]
      "#{protocol}://#{host}:#{port}/v3.0"
    end

    def monasca_hosts(nodes)
      hosts = []
      nodes.each do |n|
        hosts.push(CrowbarHelper.get_host_for_admin_url(n))
      end
      hosts
    end

    def get_host_for_monitoring_url(node)
      Chef::Recipe::Barclamp::Inventory.get_network_by_type(
        node, "monitoring"
      ).address
    end

    def network_settings(node)
      @ip ||= Chef::Recipe::Barclamp::Inventory.get_network_by_type(
        node, "monitoring"
      ).address
      @cluster_monitoring_ip ||= nil

      if node[:monasca][:ha][:enabled] && !@cluster_monitoring_ip
        @cluster_monitoring_ip = CrowbarPacemakerHelper.cluster_vip(
          node, "monitoring"
        )
      end

      if node[:monasca][:ha][:enabled]
        bind_port_api = node[:monasca][:ha][:ports][:api].to_i
        bind_port_log_api = node[:monasca][:ha][:ports][:log_api].to_i
        bind_port_kibana = node[:monasca][:ha][:ports][:kibana].to_i
        bind_port_mariadb = node[:monasca][:ha][:ports][:mariadb].to_i
        bind_port_influxdb = node[:monasca][:ha][:ports][:influxdb].to_i
        bind_port_influxdb_relay = node[:monasca][:ha][:ports][:influxdb_relay].to_i
      else
        bind_port_api = node[:monasca][:api][:bind_port].to_i
        bind_port_log_api = node[:monasca][:log_api][:bind_port].to_i
        bind_port_kibana = node[:monasca][:kibana][:bind_port].to_i
        bind_port_mariadb = node[:monasca][:mariadb][:bind_port].to_i
        bind_port_influxdb = node[:monasca][:influxdb][:bind_port].to_i
        bind_port_influxdb_relay = node[:monasca][:influxdb][:influxdb_relay].to_i
      end

      is_public_api = node[:monasca][:api][:bind_host] == "*"
      is_public_log_api = node[:monasca][:log_api][:bind_host] == "*"
      is_public_kibana = node[:monasca][:kibana][:bind_host] == "*"
      is_public_mariadb = node[:monasca][:mariadb][:bind_host] == "*"
      is_public_influxdb = node[:monasca][:influxdb][:bind_host] == "*"
      is_public_influxdb_relay = node[:monasca][:influxdb_relay][:bind_host] == "*"

      @network_settings ||= {
        ip: @ip,

        api: {
          bind_port: bind_port_api,
          ha_bind_host: is_public_api ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:api][:bind_port].to_i
        },

        log_api: {
          bind_port: bind_port_log_api,
          ha_bind_host: is_public_log_api ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:log_api][:bind_port].to_i
        },

        kibana: {
          bind_port: bind_port_kibana,
          ha_bind_host: is_public_kibana ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:kibana][:bind_port].to_i
        },

        mariadb: {
          bind_port: bind_port_mariadb,
          ha_bind_host: is_public_mariadb ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:mariadb][:bind_port].to_i
        },

        influxdb: {
          bind_port: bind_port_influxdb,
          ha_bind_host: is_public_influxdb ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:influxdb][:bind_port].to_i
        },

        # FIXME: InfluxDB Relay should be "hidden" on the same port
        # as InfluxDB, and all communication that go to /write API endpoint
        # should be relayed to InfluxDB Relay
        influxdb_relay: {
          bind_port: bind_port_influxdb_relay,
          ha_bind_host: is_public_influxdb_relay ? "0.0.0.0" : @cluster_monitoring_ip,
          ha_bind_port: node[:monasca][:influxdb_relay][:bind_port].to_i
        }
      }
    end
  end
end
