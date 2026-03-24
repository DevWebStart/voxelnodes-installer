#!/bin/bash

source lib/utils.sh
source lib/ui.sh

show_banner

# INPUT
read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -s -p "DB Password: " DBPASS; echo

echo ""
echo "Create Admin"
read -p "Username: " USER
read -p "Email: " USEREMAIL
read -s -p "Password: " USERPASS; echo
echo ""

# VALIDATION
if [[ ! "$USEREMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "❌ Invalid email"
    exit 1
fi

if [[ ! "$USER" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "❌ Invalid username"
    exit 1
fi

# SYSTEM
run "Removing Apache" "apt remove apache2 -y"
run "Updating package list" "apt update -y"

run "Installing dependencies" "
apt install -y curl wget git unzip nginx redis-server mariadb-server software-properties-common
"

# PHP 8.2
run "Installing PHP 8.2" "
add-apt-repository ppa:ondrej/php -y &&
apt update &&
apt install -y php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-fpm php8.2-curl php8.2-zip
"

run "Starting services" "
systemctl enable --now mariadb redis-server nginx php8.2-fpm
"

# DB FIX (IMPORTANT)
run "Setting up database" "
mysql -e \"DROP DATABASE IF EXISTS panel;\"
mysql -e \"CREATE DATABASE panel;\"
mysql -e \"DROP USER IF EXISTS 'pterodactyl'@'localhost';\"
mysql -e \"DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';\"
mysql -e \"CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY '$DBPASS';\"
mysql -e \"CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASS';\"
mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'localhost';\"
mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';\"
mysql -e \"FLUSH PRIVILEGES;\"
"

# PANEL
run "Downloading panel" "
mkdir -p /var/www/pterodactyl &&
cd /var/www/pterodactyl &&
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz &&
tar -xzvf panel.tar.gz &&
chmod -R 755 storage/* bootstrap/cache/
"

# COMPOSER
run "Installing Composer" "
curl -sS https://getcomposer.org/installer | php &&
mv composer.phar /usr/local/bin/composer
"

run "Installing backend" "
cd /var/www/pterodactyl &&
composer install --no-dev --optimize-autoloader
"

# ENV FIX (CRITICAL)
run "Configuring environment" "
cd /var/www/pterodactyl &&
cp .env.example .env &&
php artisan key:generate --force &&

sed -i \"s|DB_HOST=.*|DB_HOST=127.0.0.1|\" .env &&
sed -i \"s|DB_PORT=.*|DB_PORT=3306|\" .env &&
sed -i \"s|DB_DATABASE=.*|DB_DATABASE=panel|\" .env &&
sed -i \"s|DB_USERNAME=.*|DB_USERNAME=pterodactyl|\" .env &&
sed -i \"s|DB_PASSWORD=.*|DB_PASSWORD=$DBPASS|\" .env
"

run "Fixing permissions" "
chown -R www-data:www-data /var/www/pterodactyl &&
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache
"

run "Clearing cache" "
cd /var/www/pterodactyl &&
php artisan config:clear &&
php artisan cache:clear
"

run "Waiting for DB" "sleep 5"

# MIGRATION FIX
run "Running migrations" "
cd /var/www/pterodactyl &&
php artisan migrate:fresh --seed --force
"

# ADMIN FIX
run "Creating admin" "
cd /var/www/pterodactyl &&
php artisan p:user:make \
--email=$USEREMAIL \
--username=$USER \
--name-first=Admin \
--name-last=User \
--password=$USERPASS \
--admin=1
"

echo ""
echo "✅ INSTALLATION COMPLETE"
echo "🌐 http://$DOMAIN"
echo "👤 Username: $USER"
