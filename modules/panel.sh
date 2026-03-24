#!/bin/bash

source lib/utils.sh
source lib/ui.sh

LOG="/tmp/voxel_install.log"

show_banner

read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -s -p "DB Password: " DBPASS; echo

echo ""
echo "Create Admin"
read -p "Username: " USER
read -p "Email: " USEREMAIL
read -s -p "Password: " USERPASS; echo

# ---------------------------
# SAFE RUN FUNCTION (UPGRADED)
# ---------------------------
safe_run() {
    CMD=$1
    DESC=$2

    printf "➤ %s..." "$DESC"
    eval "$CMD" >> $LOG 2>&1

    if [ $? -ne 0 ]; then
        echo " ❌ FAILED"
        echo "Check log: $LOG"
        exit 1
    else
        echo " ✔"
    fi
}

# ---------------------------
# WAIT FUNCTION
# ---------------------------
wait_for_service() {
    SERVICE=$1
    for i in {1..10}; do
        systemctl is-active --quiet $SERVICE && return
        sleep 2
    done
    echo "❌ $SERVICE not ready"
    exit 1
}

# ---------------------------
# INSTALLATION
# ---------------------------

safe_run "apt update -y" "Updating packages"

safe_run "apt install -y nginx mariadb-server redis-server curl unzip git software-properties-common" "Installing dependencies"

safe_run "add-apt-repository ppa:ondrej/php -y && apt update && apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-mbstring php8.2-curl php8.2-zip php8.2-bcmath" "Installing PHP"

safe_run "systemctl enable --now nginx mariadb redis-server php8.2-fpm" "Starting services"

wait_for_service mariadb
wait_for_service php8.2-fpm

# ---------------------------
# DATABASE (OFFICIAL FORMAT)
# ---------------------------
safe_run "
mysql -e \"CREATE DATABASE IF NOT EXISTS panel;\"
mysql -e \"CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASS';\"
mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1'; FLUSH PRIVILEGES;\"
" "Setting up database"

# ---------------------------
# PANEL DOWNLOAD
# ---------------------------
safe_run "
mkdir -p /var/www/pterodactyl &&
cd /var/www/pterodactyl &&
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz &&
tar -xzvf panel.tar.gz
" "Downloading panel"

# ---------------------------
# COMPOSER
# ---------------------------
safe_run "
curl -sS https://getcomposer.org/installer | php &&
mv composer.phar /usr/local/bin/composer
" "Installing composer"

# ---------------------------
# BACKEND INSTALL
# ---------------------------
safe_run "
cd /var/www/pterodactyl &&
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
" "Installing backend"

# ---------------------------
# ENV SETUP (FULL FIX)
# ---------------------------
safe_run "
cd /var/www/pterodactyl &&
cp .env.example .env &&
php artisan key:generate --force &&
sed -i \"s|APP_URL=.*|APP_URL=http://$DOMAIN|\" .env &&
sed -i \"s|DB_HOST=.*|DB_HOST=127.0.0.1|\" .env &&
sed -i \"s|DB_DATABASE=.*|DB_DATABASE=panel|\" .env &&
sed -i \"s|DB_USERNAME=.*|DB_USERNAME=pterodactyl|\" .env &&
sed -i \"s|DB_PASSWORD=.*|DB_PASSWORD=$DBPASS|\" .env
" "Configuring environment"

# ---------------------------
# PERMISSIONS (CRITICAL)
# ---------------------------
safe_run "
chown -R www-data:www-data /var/www/pterodactyl &&
chmod -R 755 /var/www/pterodactyl &&
chmod -R 775 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache
" "Fixing permissions"

# ---------------------------
# LARAVEL RESET
# ---------------------------
safe_run "
cd /var/www/pterodactyl &&
php artisan config:clear &&
php artisan cache:clear
" "Clearing cache"

sleep 5

# ---------------------------
# MIGRATION (SAFE)
# ---------------------------
safe_run "
cd /var/www/pterodactyl &&
php artisan migrate --seed --force
" "Running migrations"

# ---------------------------
# ADMIN (NON-INTERACTIVE FIX)
# ---------------------------
safe_run "
cd /var/www/pterodactyl &&
php artisan p:user:make \
--email=$USEREMAIL \
--username=$USER \
--name-first=Admin \
--name-last=User \
--password=$USERPASS \
--admin=1
" "Creating admin"

# ---------------------------
# NGINX (AUTO SETUP)
# ---------------------------
safe_run "
cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/pterodactyl/public;

    index index.php;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
" "Configuring web server"

# ---------------------------
# FINAL HEALTH CHECK
# ---------------------------
echo ""
echo "🔍 Verifying installation..."

curl -s http://localhost | grep -q "Pterodactyl"

if [ $? -eq 0 ]; then
    echo "✅ Panel is working!"
else
    echo "❌ Panel failed final check"
    echo "Check logs: $LOG"
    exit 1
fi

echo ""
echo "🎉 INSTALL COMPLETE"
echo "🌐 http://$DOMAIN"
echo "👤 $USER"
