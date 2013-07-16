source 'http://rubygems.org'

gem 'rails', '~>3.2.12'
gem 'mysql2'
gem 'nokogiri', '~>1.6'
gem 'devise'
gem 'slim'
# TODO: Update, not straightforward
gem 'paperclip', '~>2.3.15'
gem 'coffee-script', '~>2.2'
gem 'rest-client', :require => 'rest_client'
gem 'activerecord-import'
gem "rake"
gem 'ruby-xslt'
gem 'xml-smart'
gem 'exception_notification', '~>4.0.0'
gem "dynamic_form", "~> 1.1.4"
gem 'celluloid'

group :assets do
  gem 'therubyracer', '~>0.11.0', :require => false
  gem 'sass-rails', "  ~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 2.1.2'
end

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
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
end

group :staging do
  gem 'capistrano'
  gem 'capistrano-ext'
end

group :development, :test do
  gem 'launchy'
  gem 'rspec', '~>2.14.0'
  gem 'rspec-core','~>2.14.0'
  gem 'rspec-rails', '~>2.14.0'
  gem 'capybara-webkit'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'spork', '~> 0.9.0.rc'
  gem 'cucumber'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'factory_girl'
  gem "factory_girl_rails", "~> 1.1"
end

