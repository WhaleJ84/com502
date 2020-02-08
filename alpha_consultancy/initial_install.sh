#!/usr/bin/env sh

# Ensure user is running with superuser privileges
[ $(id -u) != 0 ] && echo 'This script must be run with superuser privileges.' && exit 0

# Sets variables
user=$SUDO_USER
[ -z $user ] && read -p 'What user is running this script? ' user
home=/home/$user
binaries=$home/.local/bin
script=$(echo $0 | sed "s:$binaries::; s:\.local\/bin\/::; s:^\.\/::")

# Check to see if current script needs to be moved
if [ -e $binaries/$script ]; then
    echo 'Script is in correct location.'
else
    if [ -d $binaries ]; then
        echo 'Scripts folder exists.'
    else
        mkdir -p $binaries
        chown $user:$user $home/.local $binaries
        echo 'Scripts folder created.'
    fi
    mv $0 $binaries
    echo 'Script relocated'
    $binaries/$script
fi

# Adds personal aliases
if [ "$(tail -1 /home/$user/.bashrc)" != 'alias la="ls -alh"' ]; then
    echo 'alias scripts="cd ~/.local/bin/; la"' >> /home/$user/.bashrc
    echo 'alias la="ls -alh"' >> /home/$user/.bashrc # Ensure this is always final alias.
    source ~/.bashrc
    echo 'Aliases added to bashrc.'
fi

# Update YUM repositories and install necessary packages
yum check-update && yum install -y lynx
if [ -z $(yum list | grep docker-ce) ] 2>/dev/null; then
    curl -fsSL https://get.docker.com/ | sh
    # Start docker and make necessary changes
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $user
else
    echo 'Docker already installed.'
fi

if [ -z $(yum list | grep docker-compose) ] 2>/dev/null; then
    docker_compose_version='1.25.3'
    #docker_compose_version=$(lynx -accept-all-cookies -dump https://github.com/docker/compose/releases/ | grep -A 1 "Latest release" | tail -1 | cut -f2 -d])
    curl -L https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/$docker_compose_version/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi

exit 0
