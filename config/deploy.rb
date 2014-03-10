# Must be set before requireing multisage
set :default_stage, "staging"
set :application, "qa-reports"
require 'capistrano/ext/multistage'
require './config/deploy/capistrano_database_yml'
require 'bundler/capistrano'
require 'yaml'
require 'rvm/capistrano'
set :rvm_ruby_string, '1.9.3'
set :rvm_type, :user

set :user, 'qa-reports'
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, 'http://github.com/leonidas/qa-reports.git'
set :branch, 'dev'

ssh_options[:forward_agent] = true

# Use these if your production server needs to use proxies and you have not
# defined environmental variables so that proxy works over SSH when not in
# interactive mode
#default_environment['http_proxy']  = "http://your.proxy.com:123"
#default_environment['https_proxy'] = "http://your.proxy.com:123"

# If set to true the start and stop commands execute upstart management
# commands using sudo. Otherwise the will bundle exec passenger which does
# not kick up the service after reboot. So use upstart and allow it to be
# started and stopped without password.
set :use_upstart, false

after "deploy:setup",           "qareports:setup:setup"
after "deploy:update_code",     "qareports:symlink_shared_folders"
after "deploy:create_symlink",  "qareports:symlink_shared_files"

# http://stackoverflow.com/questions/1661586/how-can-you-check-to-see-if-a-file-exists-on-the-remote-server-in-capistrano/15436165#15436165
def remote_file_exists?(path)
  results = []

  invoke_command("if [ -e '#{path}' ]; then echo -n 'true'; fi") do |ch, stream, out|
    results << (out == 'true')
  end

  results == [true]
end

namespace :qareports do

  namespace :setup do
    desc "Setup a QA Reports installation"
    task :setup, :roles => :app do
      # Note: DB settings are handled by config/deploy/capistrano_database_yml
      qareports.setup.create_shared_folders
      qareports.setup.registeration_token
      qareports.setup.exception_notifier
      qareports.setup.bugzilla_conf
      # Upload application config
      upload("config/config.yml", "#{shared_path}/config/config.yml")
      qareports.setup.logrotate
      deploy.qadashboard.setup
    end

    desc "Create needed folders under shared folder"
    task :create_shared_folders, :roles => :app do
      # Create shared directories
      run "mkdir -p #{shared_path}/config"
      run "mkdir -p #{shared_path}/reports"
      run "mkdir -p #{shared_path}/files"
      run "mkdir -p #{shared_path}/reports/tmp"
    end

    desc "Create registration URI token"
    task :registeration_token, :roles => :app do
      registeration_token = Capistrano::CLI::ui.ask("What registeration token you want to use? (/users/<token>/register). Default: none")
      put registeration_token, "#{shared_path}/config/registeration_token"
    end

    desc "Exception notifier email addresses"
    task :exception_notifier, :roles => :app do
      email_addresses = Capistrano::CLI::ui.ask("Which email addresses should be notified in case of application errors? (Space separated list of email addresses)")
      put "%w{#{email_addresses}}", "#{shared_path}/config/exception_notifier"
    end

    desc "Settings for Bugzilla services"
    task :bugzilla_conf, :roles => :app do
      ext_conf = YAML.load_file("config/external.services.yml")

      # Go through all the defined services and ask for credentials if the
      # service is of type bugzilla
      ext_conf.each do |s|
        if s['type'] == 'bugzilla' || s['type'] == 'gerrit'
          bugzilla_http_auth = Capistrano::CLI::ui.ask("Do you want to define HTTP credentials to access #{s['name']}? Note that you should have a separate user account for this since the credentials are stored as plain text. Default: No")
          if bugzilla_http_auth =~ /yes/i
            bugzilla_uname = Capistrano::CLI::ui.ask("Please enter your HTTP username for #{s['name']}")
            bugzilla_passw = Capistrano::CLI::password_prompt("Please enter your HTTP password for #{s['name']}")
            s["http_username"] = bugzilla_uname
            s["http_password"] = bugzilla_passw
          end

          if s['type'] == 'bugzilla'
            bugzilla_auth = Capistrano::CLI::ui.ask("Do you want to define Bugzilla credentials to access #{s['name']}? Note that you should have a separate user account for this since the credentials are stored as plain text. Default: No")
            if bugzilla_auth =~ /yes/i
              bugzilla_uname = Capistrano::CLI::ui.ask("Please enter your Bugzilla username for #{s['name']}")
              bugzilla_passw = Capistrano::CLI::password_prompt("Please enter your Bugzilla password for #{s['name']}")
              s["bugzilla_username"] = bugzilla_uname
              s["bugzilla_password"] = bugzilla_passw
            end
          end
        end
      end

      put YAML::dump(ext_conf), "#{shared_path}/config/external.services.yml"
    end

    desc "Create logrotate config"
    task :logrotate, :roles => :app do
      conf = IO.read("config/logrotate.conf")
      conf["##SHARED_PATH##"] = shared_path
      # Write to shared path
      put conf, "#{shared_path}/config/logrotate.conf"
      write_file = Capistrano::CLI::ui.ask("Write logrotate conf to /etc/logrotate.d (needs passwordless sudo)? Default:no")
      if write_file =~ /yes/i
        run "cat #{shared_path}/config/logrotate.conf | sudo /usr/bin/tee /etc/logrotate.d/qa-reports"
      else
        puts "\033[36mLogrotate config written to #{shared_path}/config/logrotate.conf on remote server. Copy to /etc/logrotate.d by yourself.\033[0m"
      end
    end
  end

  desc "Symlink report folders from shared to current"
  task :symlink_shared_folders, :roles => :app do
    # Remove local directories and symlink to shared folders
    run "rm -fr #{latest_release}/public/reports"
    run "ln -nfs #{shared_path}/reports #{latest_release}/public/"
    run "ln -nfs #{shared_path}/files #{latest_release}/public/"
  end

  desc "Symlink configuration files from shared to current"
  task :symlink_shared_files, :roles => :app do
    # Remove empty token file that comes with deployment and symlink to shared
    run "rm -rf #{current_path}/config/registeration_token"
    run "ln -nfs #{shared_path}/config/registeration_token #{current_path}/config/registeration_token"

    # Symlink exception notifier config to shared
    run "ln -nfs #{shared_path}/config/exception_notifier #{current_path}/config/exception_notifier"

    # Remove current external services config file and symlink to shared
    run "rm #{current_path}/config/external.services.yml"
    run "ln -nfs #{shared_path}/config/external.services.yml #{current_path}/config/external.services.yml"

    # If old bugzilla config file exists, symlink it so it will be used
    if remote_file_exists?("#{shared_path}/config/bugzilla.yml")
      puts "\033[34mNOTICE: Using config/bugzilla.yml is deprecated. Using it anyway, but"
      puts"        see https://github.com/leonidas/qa-reports/wiki/External-Services\033[0m"
      # Remove filr from current if it exists (this may happen if someone keeps the
      # file in their own clone even if it is removed from upstream)
      if remote_file_exists?("#{current_path}/config/bugzilla.yml")
        run "rm #{current_path}/config/bugzilla.yml"
      end
      run "ln -nfs #{shared_path}/config/bugzilla.yml #{current_path}/config/bugzilla.yml"
    end

    # Remove current app config file and symlink to shared
    run "rm #{current_path}/config/config.yml"
    run "ln -nfs #{shared_path}/config/config.yml #{current_path}/config/config.yml"

    # Remove default QA Dashboard config and symlink to shared.
    run "rm #{latest_release}/config/qa-dashboard_config.yml"
    run "ln -nfs #{shared_path}/config/qa-dashboard_config.yml #{latest_release}/config/qa-dashboard_config.yml"
  end
end

namespace :deploy do
  desc "Deploy new version of config.yml"
  task :app_settings, :roles => :app do
    # https://gist.github.com/mrchrisadams/3084229/#comment-575046
    top.upload("config/config.yml", "#{shared_path}/config/config.yml")
  end

  desc "Restart the app server"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    if use_upstart
      run "sudo start ${application}"
    else
      run "cd #{current_path} && bundle exec passenger start #{current_path} --daemonize --environment #{rails_env} --port #{passenger_port}"
    end
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    if use_upstart
      run "sudo stop ${application}"
    else
      run "cd #{current_path} && bundle exec passenger stop --pid-file #{current_path}/passenger.#{passenger_port}.pid"
    end
  end

  namespace :qadashboard do
    desc "Upload QA Dashboard configuration"
    task :setup do
      # QA Dashboard configuration
      qadashboard_conf = YAML.load_file("config/qa-dashboard_config.yml")
      qadashboard_auth = Capistrano::CLI::ui.ask("Do you want to define configuration for automatic report exporting to QA Dashboard? Default: No")
      if qadashboard_auth =~ /yes/i
        qadashboard_host  = Capistrano::CLI::ui.ask("Please enter QA Dashboard URL (e.g. http://localhost:3030)")
        qadashboard_token = Capistrano::CLI::ui.ask("Please enter authentication token for report upload")
        qadashboard_conf["enabled"] = true
        qadashboard_conf["host"]    = qadashboard_host
        qadashboard_conf["token"]   = qadashboard_token
      end
      put YAML::dump(qadashboard_conf), "#{shared_path}/config/qa-dashboard_config.yml"
    end

    desc "Remove default QA Dashboard config and symlink to shared."
    task :symlink do
      run "rm #{current_path}/config/qa-dashboard_config.yml"
      run "ln -nfs #{shared_path}/config/qa-dashboard_config.yml #{current_path}/config/qa-dashboard_config.yml"
    end

    desc "Update QA Dashboard configuration"
    task :update do
      deploy.qadashboard.setup
      deploy.qadashboard.symlink
      deploy.restart
    end
  end
end
