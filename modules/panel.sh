#!/bin/bash

source lib/utils.sh
source lib/ui.sh

show_banner

echo "Pterodactyl Panel Installation"
echo ""

confirm

# ================= INPUT =================

read -p "Domain: " DOMAIN
read -p "Email: " EMAIL

read -s -p "DB Password: " DB_PASS
echo ""

echo ""
echo "Create Admin Account"

read -p "Admin Username: " ADMIN_USER
read -p "Admin Email: " ADMIN_EMAIL
read -p "Admin First Name: " ADMIN_FIRST
read -p "Admin Last Name: " ADMIN_LAST

read -s -p "Admin Password: " ADMIN_PASS
echo ""

echo ""
echo "Configuration Summary:"
echo "Domain: $DOMAIN"
echo "Admin: $ADMIN_USER"
echo ""

confirm

# ================= SYSTEM CHECK =================

run_step "Checking OS" "grep -q 'Ubuntu 22.04' /etc/os-release"
run_step "Checking root" "[ \"$EUID\" -eq 0 ]"

# ================= DEPENDENCIES =================

run_step "Updating system" "apt update -y"
run_step "Installing base packages" "apt install -y nginx mariadb-server redis-server curl unzip git software-properties-common"

# ================= PHP 8.2 =================

run_step "Adding PHP repo" "add-apt-repository ppa:ondrej/php -y"
run_step "Updating packages" "apt update -y"

run_step "Installing PHP 8.2" "apt install -y php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath"

run_step "Setting PHP default" "update-alternatives --set php /usr/bin/php8.2"

PHP_VERSION="8.2"
PHP_SOCKET="/var/run/php/php8.2-fpm.sock"

# ================= SERVICES =================

run_step "Starting MariaDB" "systemctl enable --now mariadb"
run_step "Starting Redis" "systemctl enable --now redis-server"
run_step "Starting Nginx" "systemctl enable --now nginx"
run_step "Starting PHP-FPM" "systemctl enable --now php8.2-fpm"

# ================= DATABASE =================

run_step "Creating DB" "mysql -e \"CREATE DATABASE panel;\""
run_step "Creating DB user" "mysql -e \"CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';\""
run_step "Granting DB permissions" "mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;\""

# ================= PANEL =================

run_step "Downloading panel" "mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"

run_step "Extracting panel" "cd /var/www/pterodactyl && tar -xzvf panel.tar.gz"

run_step "Installing Composer" "curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"

run_step "Installing backend" "cd /var/www/pterodactyl && composer install --no-dev --optimize-autoloader"

# ================= ENV =================

run_step "Setting env" "cd /var/www/pterodactyl && cp .env.example .env"

run_step "Configuring env" "cd /var/www/pterodactyl && sed -i 's|APP_URL=.*|APP_URL=https://$DOMAIN|' .env"

run_step "DB config" "cd /var/www/pterodactyl && sed -i 's|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|' .env"

run_step "Generating key" "cd /var/www/pterodactyl && php artisan key:generate --force"

# ================= MIGRATION =================

run_step "Running migrations" "cd /var/www/pterodactyl && php artisan migrate --seed --force"

# ================= ADMIN =================

run_step "Creating admin" "cd /var/www/pterodactyl && php artisan p:user:make --email=$ADMIN_EMAIL --username=$ADMIN_USER --name-first=$ADMIN_FIRST --name-last=$ADMIN_LAST --password=$ADMIN_PASS --admin=1"

# ================= PERMISSIONS =================

run_step "Fixing permissions" "chown -R www-data:www-data /var/www/pterodactyl"

# ================= DONE =================

echo ""
echo "✔ Installation Complete"
echo "Panel: https://$DOMAIN"
echo "Admin: $ADMIN_USER"
