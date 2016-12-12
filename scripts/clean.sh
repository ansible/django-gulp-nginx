#!/bin/bash
#
# Remove containers and images associated with the app 
#
# Pass 'all' to remove everything or 'containers' or 'images'
#

if [[ $1 == 'all' || $1 == 'containers' ]]; then
    echo "Removing all django-gulp-nginx containers..."
    containers=$(docker ps -a --format "{{.Names}}" | grep -e ansible_django -e ansible_gulp -e ansible_nginx -e ansible_postgres | wc -l | tr -d '[[:space:]]')
    if [ ${containers} -gt 0 ]; then 
        docker rm --force $(docker ps -a --format "{{.Names}}" | grep -e ansible_django -e ansible_nginx -e ansible_postgres -e ansible_gulp)
    else
        echo "No ansible_django, ansible_postgres, ansible_gulp, ansible_nginx containers found"
    fi
fi

if [[ $1 == 'all' || $1 == 'images' ]]; then
    echo "Removing all django-gulp-nginx images..."
    images=$(docker images -a --format "{{.Repository}}:{{.Tag}}" | grep django-gulp-nginx | wc -l | tr -d '[[:space:]]')
    if [ ${images} -gt 0 ]; then
        docker rmi --force $(docker images -a --format "{{.Repository}}:{{.Tag}}" | grep django-gulp-nginx)
    else
        echo "No django-gulp-nginx images found"
    fi
fi
