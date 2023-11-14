# Generating a random hexadecimal 16 characters for key of our app
APP_KEY=$(openssl rand -hex 16)

# Database Configuration Parameters
DB_NAME=snipeitdb
DB_USER=snipeituser
DB_PASSWORD=snipeitpass

# Update package index files
sudo apt update
sudo apt install dos2unix -y

# Install Git & Apache2
sudo apt install git apache2 -y

# Starting & Enabling Apache2 Service
sudo systemctl start apache2 && sudo systemctl enable apache2

# Enabling mod_rewrite module in Apache2 webserver
sudo a2enmod rewrite

# Bouncing back Apache2 service
sudo systemctl restart apache2

# Installing Mariadb Service
sudo apt install mariadb-server mariadb-client -y

# Starting & Enabling Mariadb Service
sudo systemctl start mariadb && sudo systemctl enable mariadb


# Installing expect package
sudo apt install expect -y

# mysql_secure_installation
SECURE_MYSQL=$(expect -c "
set timeout 5
spawn sudo mysql_secure_installation
expect \"Enter current password for root : \"
send \"\r\"
expect \"Switch to unix_socket authentication\"
send \"n\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"

# Installing php & its related packages
sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-bz2 php-intl php-opcache php-pdo php-calendar php-ctype php-exif php-ffi php-fileinfo php-ftp php-iconv php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap

# Installing composer
sudo curl -sS https://getcomposer.org/installer | php

# Updating path variable of composer to use it systemwide
sudo mv composer.phar /usr/local/bin/composer

#Database Configuration
sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -e "CREATE USER $DB_USER@localhost IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost;"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

cd /var/www/

# Fetching the source code
sudo git clone https://github.com/snipe/snipe-it snipe-it

cd snipe-it

# Creating environment file
sudo cp .env.example .env

# Modifying environment file
sudo sed -i "s|^\\(DB_DATABASE=\\).*|\\1$DB_NAME|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_USERNAME=\\).*|\\1$DB_USER|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_PASSWORD=\\).*|\\1$DB_PASSWORD|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(APP_URL=\\).*|\\1|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(APP_KEY=\\).*|\\1$APP_KEY|" "/var/www/snipe-it/.env"

# Giving required permissions and changing ownership of snipe-it directory
sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it

# Allowing composer to run with root privileges
COMPOSER_ALLOW_SUPERUSER=1

# Installing dependencies using composer
sudo composer -n update --no-plugins --no-scripts

# Installing dependencies using composer
sudo composer -n install --no-dev --prefer-source --no-plugins --no-scripts

# Disabling the default virtual host configuration file
sudo a2dissite 000-default.conf

# Creating new configuration for Snipe-IT app
cat << EOF > /etc/apache2/sites-available/snipe-it.conf
<VirtualHost *:80>
  ServerName snipeit.pspradhan.cloud
  DocumentRoot /var/www/snipe-it/public
  <Directory /var/www/snipe-it/public>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    allow from all
  </Directory>
</VirtualHost>
EOF

# Enabling Snipe-IT configuration file
sudo a2ensite snipe-it.conf

# Changing permissions and ownership of the folder
sudo chown -R www-data:www-data ./storage
sudo chmod -R 755 ./storage

# Bouncing back Apache2 Service
sudo systemctl restart apache2

# Removing expect package
sudo apt purge expect -y