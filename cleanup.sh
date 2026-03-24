#!/bin/bash

clear
echo "🧹 VoxelNodes Panel Cleanup"
echo ""

# CONFIRM
read -p "Are you sure you want to delete panel? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit

echo ""
echo "➤ Stopping services..."

systemctl stop nginx 2>/dev/null
systemctl stop php8.2-fpm 2>/dev/null
systemctl stop mariadb 2>/dev/null
systemctl stop redis-server 2>/dev/null
systemctl stop pteroq 2>/dev/null

echo "✔ Services stopped"

echo ""
echo "➤ Removing panel files..."

rm -rf /var/www/pterodactyl

echo "✔ Panel files removed"

echo ""
echo "➤ Removing nginx config..."

rm -f /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-available/pterodactyl.conf

systemctl restart nginx 2>/dev/null

echo "✔ Nginx cleaned"

echo ""
echo "➤ Removing cron job..."

crontab -l 2>/dev/null | grep -v "pterodactyl" | crontab -

echo "✔ Cron cleaned"

echo ""
echo "➤ Cleaning database..."

systemctl start mariadb 2>/dev/null

mysql -u root <<MYSQL_SCRIPT
DROP DATABASE panel;
DROP USER 'ptero'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "✔ Database removed"

echo ""
echo "🎉 Cleanup Complete!"
