source 'http://rubygems.org'

gem 'rails', '~>3.2.8'
gem 'i18n', '0.6.0'
gem 'mysql2'
gem 'nokogiri', '~>1.3'
gem 'devise'
gem 'slim'
gem 'paperclip', '~>2.3.15'
gem 'coffee-script', '~>2.2'
gem 'therubyracer', '~>0.9.0', :require => false
gem 'barista', '>= 0.5.0'
gem 'rest-client', :require => 'rest_client'
gem 'activerecord-import'
gem "rake"
gem 'ruby-xslt'
gem 'ruby-xml-smart'

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
  gem 'capybara'
  gem 'spork', '~> 0.9.0.rc'
  gem 'cucumber'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'factory_girl'
  gem "factory_girl_rails", "~> 1.1"
end

