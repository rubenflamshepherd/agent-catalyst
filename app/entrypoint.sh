#!/bin/sh

if [ "$ENVIRONMENT" = "prod" ]; then
    exec gunicorn --bind 0.0.0.0:8080 -w 4 'run:app'
else
    exec python run.py --debug
fi
