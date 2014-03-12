set :user, 'qa-reports'
set :application, "qa-reports.meego.com"
set :deploy_to, "/home/#{user}/#{application}"
set :rails_env, "production"
set :passenger_port, 8001
set :bundle_without, [:development, :test, :staging]

ssh_options[:port] = 2222

server "localhost", :app, :web, :db, :primary => true
host = roles[:db].servers.first.host

after "deploy:symlink" do
  # Allow robots to index qa-reports.meego.com
  run "rm #{current_path}/public/robots.txt"
  run "touch #{current_path}/public/robots.txt"
end
