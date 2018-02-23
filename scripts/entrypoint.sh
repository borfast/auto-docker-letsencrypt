#!/bin/bash

# Replace the environment variables in the "templated" script because they may
# not be available when running from the cron user.
sed -i "s/\$AWS_ACCESS_KEY_ID/${AWS_ACCESS_KEY_ID}/g" /auto-docker-letsencrypt/run_certbot.sh
sed -i "s/\$AWS_SECRET_ACCESS_KEY/${AWS_SECRET_ACCESS_KEY}/g" /auto-docker-letsencrypt/run_certbot.sh
sed -i "s/\$AWS_DEFAULT_REGION/${AWS_DEFAULT_REGION}/g" /auto-docker-letsencrypt/run_certbot.sh
sed -i "s/\$NGINX_SERVICE_NAME/${NGINX_SERVICE_NAME}/g" /auto-docker-letsencrypt/run_certbot.sh
sed -i "s/\$DOMAINS/${DOMAINS}/g" /auto-docker-letsencrypt/run_certbot.sh
sed -i "s/\$EMAIL/${EMAIL}/g" /auto-docker-letsencrypt/run_certbot.sh

sed -i "s/\$CRON_TIME/${CRON_TIME}/g" /etc/cron.d/auto-docker-letsencrypt

# Install the crontab
crontab /etc/cron.d/auto-docker-letsencrypt

exec "$@"
