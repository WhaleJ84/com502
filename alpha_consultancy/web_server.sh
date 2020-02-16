#!/usr/bin/env sh

# Ensure user is running with superuser privileges
[ $(id -u) != 0 ] && echo 'This script must be run with superuser privileges.' && exit 0

# Sets variables
user=$SUDO_USER
[ -z $user ] && read -p 'What user is running this script? ' user
home=/home/$user
docker_compose=$(whereis docker-compose | cut -f2 -d' ')
docker_version=$(docker -v | cut -f1 -d, | cut -f3 -d' ')

mkdir -p $home/docker/web_server/src && cd $home/docker/web_server
# Contains docker-compose version matrix: 'https://github.com/docker/compose/releases'
# PHP docker image: 'https://hub.docker.com/_/php'
cat << EOF > Dockerfile
FROM php:7.4.2-apache
RUN apt update && apt upgrade -y
RUN apt install -y curl libcurl4-openssl-dev libpng-dev
RUN docker-php-ext-install pdo pdo_mysql gd curl
RUN a2enmod rewrite
RUN service apache2 restart

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
EOF
# MYSQL docker image: 'https://hub.docker.com/_/mysql'
cat << EOF > docker-compose.yml
version: '3.7'
services:
    apache:
        build:
            context: ./
            dockerfile: Dockerfile
        container_name: php-7.4.2-apache
        depends_on:
            - mysql
        image: php:7.4.2-apache
        volumes:
            - ./src:/var/www/html/
        ports:
            - 80:80
            - 443:443
    mysql:
        container_name: mysql
        image: mysql
        restart: always
        environment:
            MYSQL_ROOT_PASSWORD: root
            MYSQL_DATABASE: alpha_db
            MYSQL_USER: admin
            MYQSL_PASSWORD: adminpass
        volumes:
            - ./db:/var/lib/mysql/
        ports:
            - 3306:3306
EOF
cat << EOF > src/index.php
<html>
<head>
<title>Alpha Consultancy | Homepage</title>
</head>
<body>
<h1 style='text-align:center'>Alpha Consultancy</h1>
<p style='text-align:center'>Website coming soon!</p>
</body>
</html>
<?php
phpinfo();
?>
EOF
chown -R $user:$user $home/docker/
sudo -u $user -g $user $docker_compose up -d
