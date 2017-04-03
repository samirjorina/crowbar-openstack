# Copyright 2017 FUJITSU LIMITED
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
#

unless node[:monasca][:ha][:enabled]
  log "HA support for Monasca is not enabled"
  return
end

log "Setting up Monasca HA support"

network_settings = MonascaHelper.network_settings(node)

include_recipe "crowbar-pacemaker::haproxy"

haproxy_loadbalancer "monasca-api" do
  address network_settings[:api][:ha_bind_host]
  port network_settings[:api][:ha_bind_port]
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(
    node, "monasca", "monasca-server", "monasca_api"
  )
  action :nothing
end.run_action(:create)

haproxy_loadbalancer "monasca-log-api" do
  address network_settings[:log_api][:ha_bind_host]
  port network_settings[:log_api][:ha_bind_port]
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(
    node, "monasca", "monasca-server", "monasca_log_api"
  )
  action :nothing
end.run_action(:create)

haproxy_loadbalancer "kibana" do
  address network_settings[:kibana][:ha_bind_host]
  port network_settings[:kibana][:ha_bind_port]
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(
    node, "monasca", "monasca-server", "kibana"
  )
  action :nothing
end.run_action(:create)

haproxy_loadbalancer "mariadb" do
  address network_settings[:mariadb][:ha_bind_host]
  port network_settings[:mariadb][:ha_bind_port]
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(
    node, "monasca", "monasca-server", "mariadb"
  )
  action :nothing
end.run_action(:create)

haproxy_loadbalancer "influxdb" do
  address network_settings[:influxdb][:ha_bind_host]
  port network_settings[:influxdb][:ha_bind_port]
  servers CrowbarPacemakerHelper.haproxy_servers_for_service(
    node, "monasca", "monasca-server", "influxdb"
  )
  action :nothing
end.run_action(:create)

crowbar_pacemaker_sync_mark "sync-monasca_before_ha"
