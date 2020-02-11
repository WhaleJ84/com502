#!/usr/bin/env sh

# Ensure user is running with superuse privileges
[ $(id -u) != 0 ] && echo 'This script must be run with superuser privileges.' && exit 0

# Sets variables
user=$SUDO_USER
[ -z $user ] && read -p 'What user is running this script? ' user
home=/home/$user
docker_compose=$(whereis docker-compose | cut -f2 -d' ')

mkdir -p $home/docker/ubuntu_base/ && cd $home/docker/ubuntu_base
chown -R $user:$user $home/docker

cat << EOF > Dockerfile
FROM ubuntu:latest
RUN apt update && apt upgrade -y
RUN apt install -y bash-completion less net-tools tmux vim
EOF

cat << EOF > docker-compose.yml
version: '3.7'
services:
    Ubuntu:
        build:
            context: ./
            dockerfile: Dockerfile
        container_name: ubuntu_base
        hostname: ubuntu_base
        image: ubuntu:base
EOF

docker-compose up
