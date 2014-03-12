set :user, 'qa-reports'
set :application, "qa-reports.meego.com"
set :deploy_to, "/home/#{user}/#{application}"
set :rails_env, "production"
set :passenger_port, 8001
set :bundle_without, [:development, :test, :staging]

ssh_options[:port] = 43398

server "qa-reports.meego.com", :app, :web, :db, :primary => true
host = roles[:db].servers.first.host

after "deploy:symlink" do
  # Allow robots to index qa-reports.meego.com
  run "rm #{current_path}/public/robots.txt"
  run "touch #{current_path}/public/robots.txt"
end

namespace :db do

  desc "Export production database and files to the dev env/staging"
  task :export, :roles => :db, :only => {:primary => true} do
    run "cd #{current_path} && RAILS_ENV='#{rails_env}' bundle exec rake db:dump"
    get "#{current_path}/qa_reports_production.sql.bz2", "./qa_reports_production.sql.bz2"
    run "rm #{current_path}/qa_reports_production.sql.bz2"
    `bundle exec rake db:import`
    `rsync --rsh="ssh -p #{ssh_options[:port]}" \
           --copy-links                         \
           --recursive                          \
           --verbose                            \
           --archive                            \
           --compress                           \
           #{user}@#{host}:#{current_path}/public/files/attachments public/files`
  end

  desc "Backup the production database to shared folder"
  task :backup, :roles => :db, :only => {:primary => true} do
    run "cd #{current_path} && RAILS_ENV='#{rails_env}' bundle exec rake db:dump"
    run "mv -f #{current_path}/qa_reports_production.sql.bz2 #{shared_path}/db_dumps"
  end

end
