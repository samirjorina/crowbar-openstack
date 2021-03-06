#
# Copyright 2016 SUSE Linux GmbH
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
# Cookbook Name:: trove
# Recipe:: taskmanager
#

keystone_settings = KeystoneHelper.keystone_settings(node, @cookbook_name)

trove_server = get_instance("roles:trove-server")
sql_connection = TroveHelper.get_sql_connection trove_server

rabbitmq_servers = search_env_filtered(:node, "roles:rabbitmq-server")
rabbit_trove_url = TroveHelper.get_rabbitmq_trove_url(node, rabbitmq_servers)

nova_controllers = search_env_filtered(:node, "roles:nova-controller")
nova_url, nova_insecure = TroveHelper.get_nova_details nova_controllers, keystone_settings

cinder_controllers = search_env_filtered(:node, "roles:cinder-controller")
cinder_url, cinder_insecure = TroveHelper.get_cinder_details cinder_controllers

swift_proxies = search_env_filtered(:node, "roles:swift-proxy")
ceph_radosgws = search_env_filtered(:node, "roles:ceph-radosgw")
object_store_url, object_store_insecure =
  TroveHelper.get_objectstore_details swift_proxies, ceph_radosgws

template node[:trove][:taskmanager][:config_file] do
  source "trove-taskmanager.conf.erb"
  owner node[:trove][:user]
  group node[:trove][:group]
  mode 00640
  variables(
    keystone_settings: keystone_settings,
    sql_connection: sql_connection,
    rabbit_trove_url: rabbit_trove_url,
    nova_url: nova_url,
    nova_insecure: nova_insecure,
    cinder_url: cinder_url,
    cinder_insecure: cinder_insecure,
    object_store_url: object_store_url,
    object_store_insecure: object_store_insecure
  )

  notifies :restart, "service[trove-taskmanager]"
end

trove_service("taskmanager")
