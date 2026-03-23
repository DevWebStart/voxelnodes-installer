#!/bin/bash

source lib/utils.sh
source lib/ui.sh

show_banner

echo "Pterodactyl Panel Installation"
echo ""

if [ "$DRY_RUN" != true ] && [ -d "/var/www/pterodactyl" ]; then
    echo "Panel already installed."
    exit 1
fi

confirm

# ================= INPUT =================

read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -p "DB Password: " DB_PASS

echo ""
echo "Create Admin Account"
read -p "Admin Username: " ADMIN_USER
read -p "Admin Email: " ADMIN_EMAIL
read -p "Admin First Name: " ADMIN_FIRST
read -p "Admin Last Name: " ADMIN_LAST
read -p "Admin Password: " ADMIN_PASS

# ================= PHP DETECTION =================

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_SOCKET="/var/run/php/php$PHP_VERSION-fpm.sock"

# ================= INSTALL =================

step "Installing dependencies"
run_cmd "apt update -y"
run_cmd "apt install -y nginx mariadb-server redis-server curl unzip git certbot python3-certbot-nginx"
run_cmd "apt install -y php php-cli php-fpm php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath"
done_msg "Dependencies ready"

# ================= SERVICES =================

step "Starting services"
run_cmd "systemctl enable --now mariadb"
run_cmd "systemctl enable --now redis-server"
run_cmd "systemctl enable --now nginx"
run_cmd "systemctl enable --now php$PHP_VERSION-fpm"
done_msg "Services running"

# ================= DATABASE =================

step "Configuring database"
run_cmd "mysql -e \"CREATE DATABASE panel;\""
run_cmd "mysql -e \"CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';\""
run_cmd "mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1';\""
run_cmd "mysql -e \"FLUSH PRIVILEGES;\""
done_msg "Database configured"

# ================= PANEL =================

step "Downloading panel"
run_cmd "mkdir -p /var/www/pterodactyl"
run_cmd "cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
run_cmd "cd /var/www/pterodactyl && tar -xzvf panel.tar.gz"
done_msg "Panel ready"

# ================= COMPOSER =================

step "Installing backend"
run_cmd "curl -sS https://getcomposer.org/installer | php"
run_cmd "mv composer.phar /usr/local/bin/composer"
run_cmd "cd /var/www/pterodactyl && composer install --no-dev --optimize-autoloader"
done_msg "Backend installed"

# ================= ENV CONFIG =================

step "Configuring environment"
run_cmd "cd /var/www/pterodactyl && cp .env.example .env"

run_cmd "cd /var/www/pterodactyl && sed -i 's|APP_URL=.*|APP_URL=https://$DOMAIN|' .env"
run_cmd "cd /var/www/pterodactyl && sed -i 's|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|' .env"
run_cmd "cd /var/www/pterodactyl && sed -i 's|DB_DATABASE=.*|DB_DATABASE=panel|' .env"
run_cmd "cd /var/www/pterodactyl && sed -i 's|DB_USERNAME=.*|DB_USERNAME=ptero|' .env"

run_cmd "cd /var/www/pterodactyl && php artisan key:generate --force"
done_msg "Environment configured"

# ================= MIGRATION =================

step "Running migrations"
run_cmd "cd /var/www/pterodactyl && php artisan migrate --seed --force"
done_msg "Database migrated"

# ================= ADMIN =================

step "Creating admin account"
run_cmd "cd /var/www/pterodactyl && php artisan p:user:make \
--email=$ADMIN_EMAIL \
--username=$ADMIN_USER \
--name-first=$ADMIN_FIRST \
--name-last=$ADMIN_LAST \
--password=$ADMIN_PASS \
--admin=1"
done_msg "Admin created"

# ================= PERMISSIONS =================

step "Fixing permissions"
run_cmd "chown -R www-data:www-data /var/www/pterodactyl"
run_cmd "chmod -R 755 /var/www/pterodactyl"
done_msg "Permissions fixed"

# ================= QUEUE WORKER =================

step "Setting up queue worker"

cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF

run_cmd "systemctl daemon-reexec"
run_cmd "systemctl enable --now pteroq"

done_msg "Queue worker active"

# ================= CRON =================

step "Setting up scheduler"
run_cmd "(crontab -l 2>/dev/null; echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1') | crontab -"
done_msg "Scheduler active"

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

    run_cmd "ln -s $NGINX_CONF /etc/nginx/sites-enabled/"
    run_cmd "systemctl restart nginx"

    step "Generating SSL"
    run_cmd "certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL"

    done_msg "Web server ready"
fi

# ================= FINAL =================

echo ""
done_msg "Installation Complete"
echo "Panel: https://$DOMAIN"
echo "Admin: $ADMIN_USER"
