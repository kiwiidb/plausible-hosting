#!/bin/bash
if docker ps ; then
	echo "Docker already running"
else
	echo "Docker not yet running, installing and starting now"
	sudo amazon-linux-extras install docker -y
	sudo service docker start
	sudo usermod -a -G docker ec2-user
	newgrp docker
	# Make docker auto-start
	sudo chkconfig docker on
fi
if docker-compose version ; then
	echo "docker-compose already installed"
else
	# Install docker-compose
	sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	docker-compose version
fi

# Inject configuration variables
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')
sed -i "s|%ADMIN_USER_EMAIL|$ADMIN_USER_EMAIL|g" plausible-conf.env
sed -i "s|%ADMIN_USER_NAME|$ADMIN_USER_NAME|g" plausible-conf.env
sed -i "s|%ADMIN_USER_PWD|$ADMIN_USER_PWD|g" plausible-conf.env
sed -i "s|%HOST|$HOST|g" plausible-conf.env
sed -i "s|%SECRET_KEY_BASE|$SECRET_KEY_BASE|g" plausible-conf.env

sed -i "s|%ADMIN_USER_EMAIL|$ADMIN_USER_EMAIL|g" reverse-proxy/docker-compose.caddy-gen.yml
sed -i "s|%HOST|$HOST|g" reverse-proxy/docker-compose.caddy-gen.yml

docker-compose -f docker-compose.yml -f reverse-proxy/docker-compose.caddy-gen.yml up -d