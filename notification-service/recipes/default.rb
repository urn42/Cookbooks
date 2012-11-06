include_recipe "resque"
include_recipe "unicorn"

package "freetds-dev"

app_name = "notification-service"

service app_name do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :start => true, :stop => true, :reload => true
end

host = "bitbucket.org"
repo = "git@#{host}:ilude/npi-notification-service.git"
known_hosts = "/root/.ssh/known_hosts"

directory "/root/.ssh" do
  owner "root"
  group "root"
  mode "0700"
  action :create
end

execute "add_known_host" do
  command "ssh-keyscan -t rsa #{host} >> #{known_hosts}"
  not_if { File.exists?(known_hosts) && File.read(known_hosts).include?(host) }
end

file "/root/.ssh/id_rsa" do
  content node['deploy_key']
  owner "root"
  group "root"
  mode 0600
  action :create_if_missing
end

git "#{node[:unicorn][:apps_dir]}/#{app_name}" do
  repository repo
  reference "master"
  action :sync
end

%w{tmp/sockets tmp/pids log public/data}.each do |dir|
   directory "#{node[:unicorn][:apps_dir]}/#{app_name}/#{dir}" do
      mode "0775"
      owner node[:unicorn][:user]
      group node[:unicorn][:group]
      action :create
      recursive true
   end
end

execute "unicorn_owns_apps" do
  command "chown -R #{node[:unicorn][:user]}:#{node[:unicorn][:group]} #{node[:unicorn][:apps_dir]}/#{app_name}"
  action :run
end

execute "bundler" do
  command "bundle install"
  cwd File.join(node[:unicorn][:apps_dir], app_name)
  action :run
end

template "#{app_name}.conf" do
  path "/etc/init/#{app_name}.conf"
  source "upstart.app.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :app_name => app_name
  )
  notifies :restart, resources(:service => app_name)
end

service app_name do
  provider Chef::Provider::Service::Upstart
  action [:enable, :start]
end