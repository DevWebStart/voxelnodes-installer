#!/bin/bash

install_panel() {

show_banner

read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -s -p "DB Password: " DBPASS; echo

echo ""
echo "Create Admin"
read -p "Username: " USER
read -p "Email: " USEREMAIL
read -s -p "Password: " USERPASS; echo

# PRECHECK
run "Checking DNS" "ping -c1 $DOMAIN"

# FIX APACHE
run "Removing Apache" "apt remove apache2 -y"

# SYSTEM UPDATE
run "Updating system" "apt update -y"

# INSTALL BASE
run "Installing dependencies" "apt install -y nginx mariadb-server redis-server curl unzip git software-properties-common"

# PHP
run "Installing PHP 8.2" "add-apt-repository ppa:ondrej/php -y && apt update -y && apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-mbstring php8.2-curl php8.2-zip"

# START SERVICES
run "Starting services" "systemctl enable nginx mariadb redis-server php8.2-fpm && systemctl restart nginx mariadb redis-server php8.2-fpm"

# DB SAFE CREATE
run "Setting up database" "
mysql -e \"DROP DATABASE IF EXISTS panel;\"
mysql -e \"CREATE DATABASE panel;\"
mysql -e \"DROP USER IF EXISTS 'ptero'@'127.0.0.1';\"
mysql -e \"CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DBPASS';\"
mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;\"
"

# PANEL DOWNLOAD
run "Downloading panel" "
mkdir -p /var/www/pterodactyl &&
cd /var/www/pterodactyl &&
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz &&
tar -xzvf panel.tar.gz
"

# COMPOSER
run "Installing Composer" "
curl -sS https://getcomposer.org/installer | php &&
mv composer.phar /usr/local/bin/composer
"

# BACKEND
run "Installing backend" "
cd /var/www/pterodactyl &&
composer install --no-dev --optimize-autoloader
"

# ENV FULL FIX
run "Configuring environment" "
cd /var/www/pterodactyl &&
cp .env.example .env &&
php artisan key:generate --force &&
sed -i \"s|APP_URL=.*|APP_URL=https://$DOMAIN|\" .env &&
sed -i \"s|DB_HOST=.*|DB_HOST=127.0.0.1|\" .env &&
sed -i \"s|DB_DATABASE=.*|DB_DATABASE=panel|\" .env &&
sed -i \"s|DB_USERNAME=.*|DB_USERNAME=ptero|\" .env &&
sed -i \"s|DB_PASSWORD=.*|DB_PASSWORD=$DBPASS|\" .env &&
php artisan config:clear &&
php artisan cache:clear
"

# MIGRATION
run "Running migrations" "
cd /var/www/pterodactyl &&
php artisan migrate --seed --force
"

# ADMIN CREATE
run "Creating admin" "
cd /var/www/pterodactyl &&
php artisan p:user:make <<EOF
yes
$USER
$USEREMAIL
Admin
User
$USERPASS
EOF
"

# PERMISSIONS
run "Fixing permissions" "
chown -R www-data:www-data /var/www/pterodactyl
"

# NGINX
run "Configuring web server" "
cat > /etc/nginx/sites-available/pterodactyl.conf <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/pterodactyl/public;

    index index.php;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOL
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
systemctl restart nginx
"

# SSL
run "Installing SSL" "
apt install certbot python3-certbot-nginx -y &&
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL
"

echo ""
echo "🎉 INSTALLATION COMPLETE"
echo "Panel: https://$DOMAIN"
}
