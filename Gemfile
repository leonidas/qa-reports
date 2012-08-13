source 'http://rubygems.org'

gem 'rails', '~>3.0.9'
gem 'mysql2', '~>0.2.11' # 0.3 branch only works with rails 3.1
gem 'nokogiri'
gem 'devise', '1.1.9'
gem 'fastercsv'
gem 'slim'
gem 'paperclip'
gem 'coffee-script'
gem 'therubyracer', '~>0.9.0', :require => false
gem 'barista', '>= 0.5.0'
gem 'rest-client', :require => 'rest_client'
gem 'activerecord-import'
gem "rake"

group :production do
  gem 'newrelic_rpm'
end

group :development do
  gem 'guard-rspec'
  gem 'guard-rails'
  gem 'guard-cucumber'
  gem 'guard-bundler'
  gem 'guard-spork'
  gem 'guard-migrate'
  gem 'ruby-debug'
  gem 'capistrano'
  gem 'capistrano-ext'
end

group :staging do
  gem 'capistrano'
  gem 'capistrano-ext'
end

group :development, :test do
  gem 'launchy'
  gem 'rspec', '~>2.6.0'
  gem 'rspec-core','2.6.0'
  gem 'rspec-rails', '2.6.1'
  gem 'capybara-webkit'
  gem 'capybara', '1.1.2'
  gem 'spork', '~> 0.9.0.rc'
  gem 'cucumber'
  gem 'rcov', :require => false
  gem 'cucumber-rails', '~> 0.3.2' #newer ones fail
  gem 'metric_fu', :git => "https://github.com/pyykkis/metric_fu.git"
  gem 'database_cleaner'
  gem 'factory_girl'
  gem "factory_girl_rails", "~> 1.1"
end

