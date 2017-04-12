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

package "openstack-monasca-log-agent"

log_agent_settings = node[:monasca][:log_agent]
log_agent_keystone = log_agent_settings[:keystone]
keystone_settings = KeystoneHelper.keystone_settings(node, @cookbook_name)

monasca_server = node_search_with_cache("roles:monasca-server").first
if monasca_server.nil?
  Chef::Log.warn("No monasca-server found.")
  return
end

monasca_log_api_url = MonascaHelper.log_api_public_url(monasca_server)

log_agent_dimensions = {
  hostname: node["hostname"]
}

directory "/var/log/monasca-log-agent/" do
  owner log_agent_settings["user"]
  group log_agent_settings["group"]
  mode 0o755
  recursive true
end
directory "/etc/monasca-log-agent/" do
  owner log_agent_settings["user"]
  group log_agent_settings["group"]
  mode 0o755
  recursive true
end

log_files = {
  "/var/log/messages" => "system",
  "/var/log/zypper.log" => "system"
}

ruby_block "find log files" do
  block do
    log_dirs =
      Dir.entries("/var/log")
         .select { |e| File.directory?("/var/log/#{e}") && !(e == "." || e == "..") }
    log_dirs.each { |d| log_files["/var/log/#{d}/**/*.log"] = d.downcase }
  end
end

template "/etc/monasca-log-agent/agent.conf" do
  source "log-agent.conf.erb"
  owner log_agent_settings["user"]
  group log_agent_settings["group"]
  mode 0o640
  variables(
    monasca_log_api_url: monasca_log_api_url,
    log_agent_keystone: log_agent_keystone,
    log_agent_settings: log_agent_settings,
    log_agent_dimensions: log_agent_dimensions,
    keystone_settings: keystone_settings,
    log_files: log_files
  )
  notifies :reload, "service[monasca-log-agent]"
end

service "monasca-log-agent" do
  service_name log_agent_settings[:service_name]
  supports status: true, restart: true, start: true, stop: true
  action [:disable, :stop]
  ignore_failure true
end

node.save
