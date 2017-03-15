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
# limitation.

package "ansible"
package "monasca-installer"

cookbook_file "/etc/ansible/ansible.cfg" do
  source "ansible.cfg"
  owner "root"
  group "root"
  mode "0644"
end

keystone_settings = KeystoneHelper.keystone_settings(node, @cookbook_name)
monasca_hosts = MonascaHelper.monasca_hosts(search(:node, "roles:monasca-server"))

raise "no nodes with monasca-server role found" if monasca_hosts.nil? or monasca_hosts.empty?

hosts_template =
  if monasca_hosts.length == 1
    "cmm-hosts-single.erb"
  else
    "cmm-hosts-cluster.erb"
  end

template "/opt/fujitsu/monasca-installer/cmm-hosts" do
  source hosts_template
  owner "root"
  group "root"
  mode "0644"
  variables(
    monasca_host: monasca_hosts[0],
    monasca_hosts: monasca_hosts,
    ansible_ssh_user: "root",
    offline_resources_host: CrowbarHelper.get_host_for_admin_url(node),
    keystone_host: keystone_settings["public_url_host"]
  )
  notifies :run, "execute[run ansible]", :delayed
end

template "/opt/fujitsu/monasca-installer/group_vars/all_group" do
  source "all_group.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    keystone_settings: keystone_settings
  )
  notifies :run, "execute[run ansible]", :delayed
end

# This file is used to mark that ansible installer run successfully.
# Without this, it could happen that the installer was not re-tried
# after a failed run.
file "/opt/fujitsu/monasca-installer/.installed" do
  content "cmm installed"
  owner "root"
  group "root"
  mode "0644"
  notifies :run, "execute[run ansible]", :delayed
  action :create_if_missing
end

ansible_vars = {
  influxdb_mon_api_password: node[:monasca][:master][:influxdb_mon_api_password],
  influxdb_mon_persister_password: node[:monasca][:master][:influxdb_mon_persister_password],
  database_notification_password: node[:monasca][:master][:database_notification_password],
  database_monapi_password: node[:monasca][:master][:database_monapi_password],
  database_thresh_password: node[:monasca][:master][:database_thresh_password],
  database_logapi_password: node[:monasca][:master][:database_logapi_password],
  keystone_cmm_operator_user_password:
    node[:monasca][:master][:keystone_cmm_operator_user_password],
  keystone_cmm_agent_password: node[:monasca][:master][:keystone_cmm_agent_password],
  keystone_admin_agent_password: node[:monasca][:master][:keystone_admin_agent_password],
  keystone_admin_password: keystone_settings["admin_password"],
  database_grafana_password: node[:monasca][:master][:database_grafana_password]
}.to_json

execute "run ansible" do
  command "rm -f /opt/fujitsu/monasca-installer/.installed"\
          "&& ansible-playbook -i cmm-hosts -e '#{ansible_vars}' main.yml"\
          "&& touch /opt/fujitsu/monasca-installer/.installed"
  cwd "/opt/fujitsu/monasca-installer"
  action :nothing
end
