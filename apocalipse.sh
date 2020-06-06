#!/bin/bash

#stop all containers:
# docker stop $(docker ps -a -q)
docker container ps -a -q | xargs docker container stop

#stop all containers by force
# docker kill $(docker ps -q)
docker container ps -q | xargs docker container kill

#remove all containers
# docker rm $(docker ps -a -q)
docker container ps -a -q | xargs docker container rm

#remove all docker images
# docker rmi $(docker images -q)
docker images -q | xargs docker rmi -f

#clean up any resources — images, containers, volumes, and networks — that are dangling (not associated with a container)
docker system prune -a

# Removing Volumes
docker volume rm | xargs docker volume ls