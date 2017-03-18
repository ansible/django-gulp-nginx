#!/bin/bash 

set -x

if [[ $@ == *"gunicorn"* || $@ == *"runserver"* ]]; then
    if [ -f ${DJANGO_ROOT}/manage.py ]; then
        /usr/bin/wait_on_postgres.py 
        if [ "$?" == "0" ]; then
            ${DJANGO_VENV}/bin/python manage.py migrate --fake-initial --noinput           
        fi
    fi
fi

exec "$@"
