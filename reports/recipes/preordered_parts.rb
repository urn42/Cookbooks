include_recipe "unicorn"
package "freetds-dev"

app_name = "preordered_manufactured_parts_report"

host = "bitbucket.org"
repo = "git@#{host}:rammounts/preordered_manufactured_parts_report.git"
known_hosts = "/home/#{node[:unicorn][:user]}/.ssh/known_hosts"

bash "add_known_host" do
  user  node[:unicorn][:user]
  cwd   "/home/#{node[:unicorn][:user]}"
  code  <<-EOH
  ssh-keyscan -t rsa #{host} >> #{known_hosts}
  chown #{node[:unicorn][:user]}:#{node[:unicorn][:group]} #{known_hosts}
  chmod 600 #{known_hosts}
  EOH
  not_if { File.exists?(known_hosts) && File.read(known_hosts).include?(host) }
end

git "#{node[:unicorn][:apps_dir]}/#{app_name}" do
  repository repo
  reference "master"
  action :sync
  user node[:unicorn][:user]
  group node[:unicorn][:group]
end

execute "deployment bundler" do
  command "bundle install --deployment --without development test"
  user node[:unicorn][:user]
  group node[:unicorn][:group]
  cwd File.join(node[:unicorn][:apps_dir], app_name)
  action :run
end

cron "preordered parts report" do
  hour "7"
  minute "01"
  command "cd #{node[:unicorn][:apps_dir]}/#{app_name}; /usr/local/bin/bundle exec /usr/local/bin/ruby preordered_parts.rb"
end