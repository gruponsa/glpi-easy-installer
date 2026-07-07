#!/usr/bin/env bash

set -e

#######################################
# GLPI Easy Installer
# Version 1.0
# Gruponsa
#######################################

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${BLUE}"
cat << "EOF"

   ____ _     ____ ___
  / ___| |   |  _ \_ _|
 | |  _| |   | |_) | |
 | |_| | |___|  __/| |
  \____|_____|_|  |___|

      GLPI EASY INSTALLER
          Version 1.0

EOF
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta como root."
    exit 1
fi

if ! grep -qi debian /etc/os-release; then
    echo "Solo Debian."
    exit 1
fi

echo
read -p "Dominio o IP: " DOMAIN

read -p "Nombre de la Base de Datos [glpi]: " DBNAME
DBNAME=${DBNAME:-glpi}

read -p "Usuario de la BD [glpi]: " DBUSER
DBUSER=${DBUSER:-glpi}

read -s -p "Password de la BD: " DBPASS
echo

echo
echo "Actualizando sistema..."
apt update
apt -y upgrade

echo
echo "Instalando dependencias..."

apt install -y \
apache2 \
mariadb-server \
wget \
curl \
unzip \
php \
php-cli \
php-common \
php-mysql \
php-gd \
php-intl \
php-mbstring \
php-curl \
php-xml \
php-zip \
php-bcmath \
php-imap \
php-ldap \
php-apcu

systemctl enable apache2
systemctl enable mariadb

systemctl restart mariadb

echo
echo "Creando Base de Datos..."

mysql <<EOF
CREATE DATABASE IF NOT EXISTS $DBNAME
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DBUSER'@'localhost'
IDENTIFIED BY '$DBPASS';

GRANT ALL PRIVILEGES
ON $DBNAME.*
TO '$DBUSER'@'localhost';

FLUSH PRIVILEGES;
EOF

echo
echo "Descargando GLPI..."

cd /tmp

wget -O glpi.tgz \
https://github.com/glpi-project/glpi/releases/latest/download/glpi.tgz

rm -rf /var/www/glpi

tar xzf glpi.tgz

mv glpi /var/www/

chown -R www-data:www-data /var/www/glpi

find /var/www/glpi -type d -exec chmod 755 {} \;
find /var/www/glpi -type f -exec chmod 644 {} \;

echo
echo "Configurando Apache..."

cat >/etc/apache2/sites-available/glpi.conf <<EOF
<VirtualHost *:80>

ServerName $DOMAIN

DocumentRoot /var/www/glpi/public

<Directory /var/www/glpi/public>

AllowOverride All

Require all granted

</Directory>

ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined

</VirtualHost>
EOF

a2enmod rewrite

a2ensite glpi

a2dissite 000-default

systemctl restart apache2

echo
echo "Configurando PHP..."

PHPVER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

cat >/etc/php/$PHPVER/apache2/conf.d/99-glpi.ini <<EOF
memory_limit=512M
upload_max_filesize=128M
post_max_size=128M
max_execution_time=300
date.timezone=America/Mexico_City
EOF

systemctl restart apache2

clear

echo
echo "========================================="
echo "      INSTALACION FINALIZADA"
echo "========================================="
echo
echo "URL:"
echo
echo "http://$DOMAIN"
echo
echo "Base de Datos:"
echo "$DBNAME"
echo
echo "Usuario:"
echo "$DBUSER"
echo
echo "Ahora completa el asistente web."
echo
