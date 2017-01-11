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
# TODO: Fill this with code that deploys the Monasca backend services

### Example code for retrieving a database URL and keystone settings:

keystone_settings = KeystoneHelper.keystone_settings(node, @cookbook_name)

# db_settings = fetch_database_settings
# db_conn_scheme = db_settings[:url_scheme]

# if db_settings[:backend_name] == "mysql"
#  db_conn_scheme = "mysql+pymysql"
# end

# database_connection = "#{db_conn_scheme}://" \
# "#{node[:monasca][:db][:user]}" \
# ":#{node[:monasca][:db][:password]}" \
#  "@#{db_settings[:address]}" \
#  "/#{node[:monasca][:db][:database]}"


monasca_port = node[:monasca][:api][:bind_port]
ssl_enabled = node[:monasca][:api][:ssl]
monasca_protocol = ssl_enabled ? "https" : "http"
ha_enabled = node[:monasca][:ha][:enabled]

my_admin_host = CrowbarHelper.get_host_for_admin_url(node, ha_enabled)
my_public_host = CrowbarHelper.get_host_for_public_url(
  node, ssl_enabled, ha_enabled
)

register_auth_hash = { user: keystone_settings["admin_user"],
                       password: keystone_settings["admin_password"],
                       tenant: keystone_settings["admin_tenant"] }



keystone_register "monasca server wakeup keystone" do
  protocol keystone_settings["protocol"]
  insecure keystone_settings["insecure"]
  host keystone_settings["internal_url_host"]
  port keystone_settings["admin_port"]
  auth register_auth_hash
  action :wakeup
end


keystone_register "register monasca user" do
  protocol keystone_settings["protocol"]
  insecure keystone_settings["insecure"]
  host keystone_settings["internal_url_host"]
  port keystone_settings["admin_port"]
  auth register_auth_hash
  user_name keystone_settings["service_user"]
  user_password keystone_settings["service_password"]
  tenant_name keystone_settings["service_tenant"]
  action :add_user
end

keystone_register "give monasca user access" do
  protocol keystone_settings["protocol"]
  insecure keystone_settings["insecure"]
  host keystone_settings["internal_url_host"]
  port keystone_settings["admin_port"]
  auth register_auth_hash
  user_name keystone_settings["service_user"]
  tenant_name keystone_settings["service_tenant"]
  role_name "admin"
  action :add_access
end

keystone_register "register monasca service" do
  protocol keystone_settings["protocol"]
  insecure keystone_settings["insecure"]
  host keystone_settings["internal_url_host"]
  port keystone_settings["admin_port"]
  auth register_auth_hash
  service_name "monasca"
  service_type "monitoring"
  service_description "Monasca monitoring service"
  action :add_service
end

keystone_register "register monasca endpoint" do
  protocol keystone_settings["protocol"]
  insecure keystone_settings["insecure"]
  host keystone_settings["internal_url_host"]
  port keystone_settings["admin_port"]
  auth register_auth_hash
  endpoint_service "monasca"
  endpoint_region keystone_settings["endpoint_region"]
  endpoint_publicURL "#{monasca_protocol}://#{my_public_host}:#{monasca_port}/v2.0"
  endpoint_adminURL "#{monasca_protocol}://#{my_admin_host}:#{monasca_port}/v2.0"
  endpoint_internalURL "#{monasca_protocol}://#{my_admin_host}:#{monasca_port}/v2.0"
  action :add_endpoint_template
end
