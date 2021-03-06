#!/usr/bin/env bash

# Vagrant provisioning script for QA Reports production environment. This is not
# intended to be used in setting up proper production environment but rather
# for testing the documentation. This provisioning script installs the packages
# mentioned in users guide and creates required configuration files so that
# you should be able to deploy to the vagrant box and test how things work.

# In case you after all use this in production notice that
# - ROOT PASSWORD IS NOT SET FOR MARIADB!
# - MARIADB USER PASSWORD IS KNOWN TO THE WORLD! (since it's in this file)
# - SSH SERVER IS NOT SECURED

export DEBIAN_FRONTEND=noninteractive

username='qa-reports'
userpass='password'
dbname='qa_reports_production'
dbuser='qa_reports'
dbpass='password'

# To which port Passenger binds. This must be the same in deploy config
passenger_port=8001
# Where to deploy. This must be the same in deploy config
deploy_to="/home/${username}/qa-reports.meego.com"

# MariaDB. Check correct APT source for your release from
# https://downloads.mariadb.org/mariadb/repositories/#mirror=yamagata-university&distro=Ubuntu
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
echo 'deb http://ftp.heanet.ie/mirrors/mariadb/repo/5.5/ubuntu precise main' > /etc/apt/sources.list.d/mariadb.list

apt-get update

# Packages needed
rvm_needs='libyaml-0-2 curl gawk libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison libffi-dev'
gem_needs='build-essential libxml2-dev libxslt1-dev libmariadbclient-dev libssl-dev libcurl4-openssl-dev'
deployment_needs='git'
server_needs='nginx mariadb-server'

# Now install everything on the same call to save some time
apt-get -y install $rvm_needs $gem_needs $deployment_needs $server_needs

grep -e "^ListenAddress" /etc/ssh/sshd_config || echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config

adduser --disabled-password --gecos "" qa-reports
echo qa-reports:password | chpasswd

mysql -u root <<EOF
  CREATE DATABASE IF NOT EXISTS ${dbname};
  GRANT ALL ON ${dbname}.* TO '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';
  FLUSH PRIVILEGES;
EOF

cat > /etc/nginx/sites-available/qa-reports <<EOF

server {
  server_name localhost;
  listen 80;

  root ${deploy_to}/current/public;

  gzip on;
  gzip_http_version 1.1;
  gzip_vary on;
  gzip_comp_level 6;
  gzip_proxied any;
  gzip_types text/html text/plain text/css application/json application/x-javascript text/javascript;
  gzip_buffers 16 8k;
  gzip_disable “MSIE [1-6].(?!.*SV1)”;
  add_header X-UA-Compatible IE=edge,chrome=1;

  location ~ ^/(assets)/  {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  location / {
    proxy_pass http://localhost:${passenger_port};
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_buffering off;
  }
}

EOF

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/qa-reports /etc/nginx/sites-enabled/default
service nginx restart

sudo su - $username -c 'curl -sSL https://get.rvm.io | bash'
sudo su - $username <<EOF
  rvm autolibs fail
  rvm install 1.9.3 || echo -e "\nInstall the listed missing requirements manually, then rvm install 1.9.3 as $username\n"
EOF


cat <<EOF
  You can now try to deploy production environment. Settings:

  SSH host: localhost
  SSH port: 2222
  Username: $username
  Password: $userpass
  DB name:  $dbname
  DB user:  $dbuser
  DB pass:  $dbpass

  Passenger bind to port $passenger_port

  Deploy:

ssh-copy-id "${username}@localhost -p 2222"
cap vagrant deploy:setup
cap vagrant deploy:migrations

  And finally after deployment, run:

vagrant ssh
mysql -u root <<SQL
  USE qa_reports_production;

  INSERT IGNORE INTO releases SET name='1.3', sort_order=1;
  INSERT IGNORE INTO releases SET name='1.2', sort_order=2;
  INSERT IGNORE INTO releases SET name='1.1', sort_order=3;

  INSERT IGNORE INTO profiles SET name='Core', sort_order=1;
  INSERT IGNORE INTO profiles SET name='Handset', sort_order=2;
  INSERT IGNORE INTO profiles SET name='Netbook', sort_order=3;
  INSERT IGNORE INTO profiles SET name='IVI', sort_order=4;
  INSERT IGNORE INTO profiles SET name='SDK', sort_order=5;
SQL
sudo cp /home/qa-reports/qa-reports.meego.com/shared/config/qa-reports.meego.com.conf /etc/init
sudo start qa-reports.meego.com

  You should now be able to access QA Reports from
  http://localhost:9000

EOF
