#!/bin/bash

docker compose -f /server-installation-docker-jenkins-portainer/docker-compose.server.yml down
rm -rf /server-installation-docker-jenkins-portainer
docker swarm leave --force
