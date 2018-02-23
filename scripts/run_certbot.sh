#!/bin/bash

AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
PYTHON=$(/usr/local/bin/pipenv --py)

if test ! -f /var/run/auto-docker-letsencrypt.lock
  then
    touch /var/run/auto-docker-letsencrypt.lock
    cd /auto-docker-letsencrypt
    python3 -c 'import random; import time; time.sleep(random.random() * 3600)'
    /usr/local/bin/pipenv run certbot certonly --dns-route53 --agree-tos -n --agree-tos --email $EMAIL --domains $DOMAINS --post-hook '${PYTHON} /auto-docker-letsencrypt/restart-nginx.py $NGINX_SERVICE_NAME'
    rm -rf /var/run/auto-docker-letsencrypt.lock
fi
