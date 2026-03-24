#!/bin/bash

source lib/utils.sh
source lib/ui.sh

show_banner

# SAFE INPUT
read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -s -p "DB Password: " DBPASS; echo
echo ""

echo "Create Admin"
read -p "Username: " USER
read -p "Email: " USEREMAIL
read -s -p "Password: " USERPASS; echo
echo ""

# VALIDATION (CRITICAL FIX)
if [[ ! "$USEREMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "❌ Invalid email"
    exit 1
fi

if [[ ! "$USER" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "❌ Invalid username"
    exit 1
fi

run "Removing Apache" "apt remove apache2 -y"
run "Updating system" "apt update -y && apt upgrade -y"

run "Installing dependencies" "
apt install -y curl wget git unzip nginx redis-server mariadb-server software-properties-common
"

run "Installing PHP 8.2" "
add-apt-repository ppa:ondrej/php -y &&
apt update &&
apt install -y php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-fpm php8.2-curl php8.2-zip
"

run "Starting services" "
systemctl enable --now mariadb redis-server nginx php8.2-fpm
"

run "Setting DB" "
mysql -e \"CREATE DATABASE panel;\"
mysql -e \"CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DBPASS';\"
mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;\"
"

run "Downloading panel" "
mkdir -p /var/www/pterodactyl &&
cd /var/www/pterodactyl &&
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz &&
tar -xzvf panel.tar.gz &&
chmod -R 755 storage/* bootstrap/cache/
"

run "Installing Composer" "
curl -sS https://getcomposer.org/installer | php &&
mv composer.phar /usr/local/bin/composer
"

run "Installing backend" "
cd /var/www/pterodactyl &&
composer install --no-dev --optimize-autoloader
"

run "Configuring env" "
cd /var/www/pterodactyl &&
cp .env.example .env &&
php artisan key:generate --force
"

run "DB config" "
cd /var/www/pterodactyl &&
sed -i \"s/DB_PASSWORD=.*/DB_PASSWORD=$DBPASS/\" .env
"

run "Clear cache" "
cd /var/www/pterodactyl &&
php artisan config:clear &&
php artisan cache:clear
"

run "Running migrations" "
cd /var/www/pterodactyl &&
php artisan migrate --seed --force
"

# ✅ FINAL ADMIN FIX
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
echo "✅ PANEL INSTALLED"
echo "🌐 http://$DOMAIN"
echo "👤 $USER"
