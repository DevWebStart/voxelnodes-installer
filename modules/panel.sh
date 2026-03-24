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

# ================= SUMMARY =================

echo ""
echo "Configuration Summary:"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Admin: $ADMIN_USER"
echo ""

confirm

# ================= INSTALL =================

run_step "Updating system" "apt update -y"

run_step "Installing core dependencies" "apt install -y nginx mariadb-server redis-server curl unzip git certbot python3-certbot-nginx"

# 🔥 Install PHP FIRST (FIXED)
run_step "Installing PHP" "apt install -y php php-cli php-fpm php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath"

# 🔥 Ensure PHP installed
if ! command -v php >/dev/null 2>&1; then
    fail_msg "PHP installation failed"
    exit 1
fi

# ================= PHP DETECTION =================

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_SOCKET="/var/run/php/php$PHP_VERSION-fpm.sock"

# ================= SERVICES =================

run_step "Starting MariaDB" "systemctl enable --now mariadb"
run_step "Starting Redis" "systemctl enable --now redis-server"
run_step "Starting Nginx" "systemctl enable --now nginx"
run_step "Starting PHP-FPM" "systemctl enable --now php$PHP_VERSION-fpm"

# ================= DATABASE =================

run_step "Creating database" "mysql -e \"CREATE DATABASE panel;\""
run_step "Creating DB user" "mysql -e \"CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';\""
run_step "Granting permissions" "mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;\""

# ================= PANEL =================

run_step "Downloading panel" "mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"

run_step "Extracting panel" "cd /var/www/pterodactyl && tar -xzvf panel.tar.gz"

# ================= COMPOSER =================

run_step "Installing Composer" "curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"

run_step "Installing backend" "cd /var/www/pterodactyl && composer install --no-dev --optimize-autoloader"

# ================= ENV =================

run_step "Setting environment" "cd /var/www/pterodactyl && cp .env.example .env"

run_step "Configuring environment" "cd /var/www/pterodactyl && sed -i 's|APP_URL=.*|APP_URL=https://$DOMAIN|' .env"

run_step "Setting DB config" "cd /var/www/pterodactyl && sed -i 's|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|' .env"

run_step "Finalizing env" "cd /var/www/pterodactyl && sed -i 's|DB_DATABASE=.*|DB_DATABASE=panel|' .env && sed -i 's|DB_USERNAME=.*|DB_USERNAME=ptero|' .env"

run_step "Generating app key" "cd /var/www/pterodactyl && php artisan key:generate --force"

# ================= MIGRATION =================

run_step "Running migrations" "cd /var/www/pterodactyl && php artisan migrate --seed --force"

# ================= ADMIN =================

run_step "Creating admin" "cd /var/www/pterodactyl && php artisan p:user:make \
--email=$ADMIN_EMAIL \
--username=$ADMIN_USER \
--name-first=$ADMIN_FIRST \
--name-last=$ADMIN_LAST \
--password=$ADMIN_PASS \
--admin=1"

# ================= PERMISSIONS =================

run_step "Fixing permissions" "chown -R www-data:www-data /var/www/pterodactyl && chmod -R 755 /var/www/pterodactyl"

# ================= QUEUE =================

step "Setting up queue"

cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low

[Install]
WantedBy=multi-user.target
EOF

run_step "Starting queue worker" "systemctl daemon-reexec && systemctl enable --now pteroq"

# ================= CRON =================

run_step "Setting scheduler" "(crontab -l 2>/dev/null; echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1') | crontab -"

# ================= NGINX =================

read -p "Setup web server & SSL? (y/n): " WEB

if [[ "$WEB" == "y" ]]; then

    step "Configuring Nginx"

    NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"

    cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

    run_step "Enabling site" "ln -s $NGINX_CONF /etc/nginx/sites-enabled/"
    run_step "Restarting Nginx" "systemctl restart nginx"

    run_step "Installing SSL" "certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL"

fi

# ================= FINAL =================

echo ""
done_msg "Installation Complete"
echo "Panel: https://$DOMAIN"
echo "Admin: $ADMIN_USER"
