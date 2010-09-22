require  File.join(File.dirname(__FILE__), '../lib/plover')
require 'pathname'
set :rails_root, Pathname.new(ENV['RAILS_ROOT'] || Dir.pwd)
set :plover_yml_path, rails_root.join('config', 'plover.yml')
set :plover_cloud_config_path, rails_root.join('config', 'cloud-config.txt')

set :plover_yml do
  if plover_yml_path.exist?
    require 'yaml'
    YAML::load(plover_yml_path.read)
  else
    puts "Missing #{plover_yml_path}"
    exit(1)
  end
end

desc "[internal]: populate capistrano with settings from plover.yml"
task :configure_plover do
  plover_yml.each do |key, value|
    set key.to_sym, value
  end
  Plover::Connection.establish_connection_with_config_file(plover_yml_path)
end

desc "[internal]: populate capistrano with settings from plover_servers.yml"
task :configure_plover_roles do
  configure_plover
  Plover::Connection.server_list.each do |server|
    role server.role.to_sym, server.dns_name
  end
end

namespace :plover do
  
  desc "Provision servers at EC2 using Plover"
  task :provision do
    configure_plover
    Plover::Connection.provision_servers
  end

  desc "List servers at EC2 started by Plover"
  task :list do
    configure_plover
    Plover::Connection.running_servers
  end
  
  desc "List servers at EC2 started by Plover"
  task :list_fog do
    configure_plover
    puts Plover::Connection.servers.inspect
  end
  
  desc "List servers at EC2 using Plover"
  task :list_roles do
    configure_plover
    configure_plover_roles
    puts "Roles: #{roles.inspect}"
  end
  
  desc "Upload plover_servers.yml to the EC2 servers"
  task :upload_server_yaml do
    upload("config/plover_servers.yml", "#{current_release}/config/plover_servers.yml")
  end
  
  desc "Shutdown servers at EC2 using Plover"
  task :shutdown do
    configure_plover
    Plover::Connection.shutdown_servers
  end
  
end