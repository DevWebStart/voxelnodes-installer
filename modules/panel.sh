#!/bin/bash

install_panel() {

show_banner
echo "Pterodactyl Panel Installation"
echo ""

read -p "Proceed? (y/n): " confirm
[[ "$confirm" != "y" ]] && return

read -p "Domain: " DOMAIN
read -p "Email: " EMAIL
read -s -p "DB Password: " DBPASS
echo ""

echo ""
echo "Create Admin Account"
read -p "Admin Username: " USERNAME
read -p "Admin Email: " USEREMAIL
read -p "Admin First Name: " FIRSTNAME
read -p "Admin Last Name: " LASTNAME
read -s -p "Admin Password: " USERPASS
echo ""

echo ""
echo "Configuration Summary:"
echo "Domain: $DOMAIN"
echo "Admin: $USERNAME"

read -p "Proceed? (y/n): " confirm2
[[ "$confirm2" != "y" ]] && return

# FIX APACHE CONFLICT
step "Removing Apache (if installed)"
systemctl stop apache2 2>/dev/null
systemctl disable apache2 2>/dev/null
apt remove apache2 -y > /dev/null 2>&1

# SYSTEM UPDATE
step "Updating system"
apt update -y > /dev/null 2>&1

# INSTALL DEPENDENCIES
step "Installing dependencies"
apt install -y nginx mariadb-server redis-server curl unzip git software-properties-common > /dev/null 2>&1

# PHP 8.2
step "Installing PHP 8.2"
add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
apt update -y > /dev/null 2>&1
apt install -y php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath > /dev/null 2>&1

# START SERVICES
systemctl enable nginx mariadb redis-server php8.2-fpm > /dev/null 2>&1
systemctl start nginx mariadb redis-server php8.2-fpm > /dev/null 2>&1

success "Services started"

# DATABASE
step "Configuring database"
mysql -e "CREATE DATABASE panel;" 2>/dev/null
mysql -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DBPASS';"
mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"
success "Database ready"

# PANEL
step "Downloading panel"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz > /dev/null 2>&1
tar -xzvf panel.tar.gz > /dev/null 2>&1

# COMPOSER
step "Installing Composer"
curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
mv composer.phar /usr/local/bin/composer

# BACKEND
step "Installing backend"
composer install --no-dev --optimize-autoloader > /dev/null 2>&1

# ENV
cp .env.example .env
php artisan key:generate --force > /dev/null 2>&1

# AUTO CONFIG ENV
sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DBPASS|" .env

# MIGRATE
php artisan migrate --seed --force > /dev/null 2>&1

# CREATE ADMIN
php artisan p:user:make <<EOF
yes
$USERNAME
$USEREMAIL
$FIRSTNAME
$LASTNAME
$USERPASS
EOF

# PERMISSIONS
chown -R www-data:www-data /var/www/pterodactyl

# NGINX CONFIG
step "Configuring Nginx"
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

# SSL
step "Installing SSL"
apt install certbot python3-certbot-nginx -y > /dev/null 2>&1
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL > /dev/null 2>&1

success "Installation Complete"
echo "Panel: https://$DOMAIN"
echo "Admin: $USERNAME"
}
