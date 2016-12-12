#!/bin/bash

# Run django management command

cd ${DJANGO_ROOT}
${DJANGO_VENV}/bin/python ./manage.py "$@"
