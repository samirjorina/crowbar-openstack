module MonascaHelper
  def self.api_public_host(node)
    ha_enabled = node[:monasca][:ha][:enabled]
    ssl_enabled = node[:monasca][:api][:ssl]
    CrowbarHelper.get_host_for_public_url(node, ssl_enabled, ha_enabled)
  end

  def self.api_public_url(node)
    host = api_public_host(node)
    protocol = node[:monasca][:api][:ssl] ? "https" : "http"
    port = node[:monasca][:api][:bind_port]
    "#{protocol}://#{host}:#{port}/v2.0"
  end

  def self.api_admin_host(node)
    ha_enabled = node[:monasca][:ha][:enabled]
    CrowbarHelper.get_host_for_admin_url(node, ha_enabled)
  end

  def self.api_admin_url(node)
    host = api_admin_host(node)
    protocol = node[:monasca][:api][:ssl] ? "https" : "http"
    port = node[:monasca][:api][:bind_port]
    "#{protocol}://#{host}:#{port}/v2.0"
  end
end
