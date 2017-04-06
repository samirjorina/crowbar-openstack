#
# Copyright 2016 SUSE Linux GmbH
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
# limitation.

monasca_debug = false
monasca_ha_enabled = false

monasca_metric_agent_service_name = "monasca-agent"
monasca_log_agent_service_name = "monasca-log-agent"

default[:monasca][:platform] = {
  packages: [],
  services: [
    monasca_metric_agent_service_name,
    monasca_log_agent_service_name
  ]
}

default[:monasca][:db][:database] = "monasca"
default[:monasca][:db][:user] = "monasca"
default[:monasca][:db][:password] = nil # must be set by wrapper

override[:monasca][:group] = "monasca"
override[:monasca][:user] = "monasca"

default[:monasca][:debug] = monasca_debug

# metric-agent default service settings
default[:monasca][:metric_agent][:service_name] = monasca_metric_agent_service_name
default[:monasca][:metric_agent][:user] = "monasca-agent"
default[:monasca][:metric_agent][:group] = "monasca"
default[:monasca][:metric_agent][:debug] = monasca_debug
default[:monasca][:metric_agent][:agent_service_name] = "openstack-monasca-agent"

# log-agent default service settings
default[:monasca][:log_agent][:service_name] = monasca_log_agent_service_name
default[:monasca][:log_agent][:user] = "monasca-log-agent"
default[:monasca][:log_agent][:group] = "logstash"
default[:monasca][:log_agent][:debug] = monasca_debug

# default[:monasca][:api][:bind_host] = "*"
# default[:monasca][:log_api][:bind_host] = "*"
# default[:monasca][:kibana][:bind_host] = "*"
# default[:monasca][:mariadb][:bind_host] = "-"
# default[:monasca][:influxdb][:bind_host] = "-"

default[:monasca][:ha][:enabled] = monasca_ha_enabled
# Ports to bind to when haproxy is used for the real ports
# Public network
default[:monasca][:ha][:ports][:api] = 18070
default[:monasca][:ha][:ports][:log_api] = 15607
default[:monasca][:ha][:ports][:kibana] = 15601
# Internal network
default[:monasca][:ha][:ports][:mariadb] = 13306
default[:monasca][:ha][:ports][:influxdb] = 18086
default[:monasca][:ha][:ports][:influxdb_relay] = 9096
