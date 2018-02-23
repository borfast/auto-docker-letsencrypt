FROM python:3.7-slim

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install apt-transport-https ca-certificates curl cron gnupg2 software-properties-common openssl
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get -y install docker-ce docker-ce-cli containerd.io

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

RUN mkdir /auto-docker-letsencrypt
WORKDIR /auto-docker-letsencrypt

RUN pip3 install pipenv
COPY ./Pipfile /auto-docker-letsencrypt/Pipfile
COPY ./Pipfile.lock /auto-docker-letsencrypt/Pipfile.lock
RUN pipenv install --ignore-pipfile

COPY ./crontab /etc/cron.d/auto-docker-letsencrypt
RUN chmod 0644 /etc/cron.d/auto-docker-letsencrypt
RUN touch /var/log/cron.log

COPY ./restart-nginx.py /auto-docker-letsencrypt/restart-nginx.py
RUN chmod a+x /auto-docker-letsencrypt/restart-nginx.py

COPY ./scripts/run_certbot.sh /auto-docker-letsencrypt/run_certbot.sh
RUN chmod a+x /auto-docker-letsencrypt/run_certbot.sh

COPY ./scripts/entrypoint.sh /auto-docker-letsencrypt/entrypoint.sh
ENTRYPOINT [ "/bin/bash", "/auto-docker-letsencrypt/entrypoint.sh" ]

CMD cron -f
