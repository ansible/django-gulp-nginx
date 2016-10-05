#!/bin/bash

cd /django
${DJANGO_VENV}/bin/python ./manage.py "$@"
