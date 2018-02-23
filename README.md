# Auto Docker Let's Encrypt

Dockerized [certbot](http://certbot.eff.org/) to be run as a sidecar in a 
multi-container environment.

The container has certbot to generate a certificate for all the specified
domains and runs a cron daemon to automatically renew the certificate.


### Assumptions

* This uses Certbot's AWS Route53 DNS for domain ownership verification, which
means you must use Route53 for the domain's DNS configuration. Pull requests to
support other DNS providers or certbot verification mechanisms are welcome.

* A container running this image exists in a cluster of containers, just like 
any other service. For now, this targets Docker Swarm or Compose. Pull requests
to support other platforms are welcome.

* Nginx is the web server that will use the generated certificate. Pull
requests to support other web servers are welcome. 


### Shared volumes
When running the container, you will need to mount a few volumes:
* a couple of let's encrypt directories, namely `/etc/letsencrypt` and
`/var/lib/letsencrypt`.
* Docker's socket from the host machine (which needs to be the Swarm manager)
in `/var/run/docker.sock`.

The Docker socket from the host is necessary because the nginx restart script
needs to communicate with the swarm manager, and thus *this container needs to
run on a manager node*.


### Environment variables

You also need to pass a few environment variables:
* **DOMAINS**: the comma-separated list of domains to handle.
* **NGINX_SERVICE_NAME**: the name of the nginx Docker service. 
* **EMAIL**: the email address to be used for the certificate registration.
* **CRON_TIME**: a cron-compatible time definition of the time at which you
want the cron job to run, like `0 2,14 * * *`.
* **AWS_ACCESS_KEY_ID**, **AWS_SECRET_ACCESS_KEY**, **AWS_DEFAULT_REGION**: the
AWS keys and default region.


### Notes

*Important*: the job is supposed to run twice a day, as per Let's Encrypt
recommendation, so that if they need to revoke a certificate before it's time
to renew it, we won't be left without a functioning certificate for too long.

*Also important*: We try to add a bit of randomness to the time the renewal
process is run so that not every renewal request runs at the same time,
contributing to overload Let's Encrypt's servers. That's what the Python bit at
the beginning of the cron command does: it `sleep`s for a random number of
minutes before actually running the renewal command. 


### How to use

If you're adding this to Docker Swarm or Compose, the service definition would
look something like this:
```
auto-docker-letsencrypt:
  image: auto-docker-letsencrypt
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt
    - /var/lib/letsencrypt:/var/lib/letsencrypt
    - /var/run/docker.sock:/var/run/docker.sock
  environment:
    - DOMAINS=sub1.domain1.com,sub2.domain1.com,domain2.org,sub.domain3.net
    - NGINX_SERVICE_NAME=my_nginx_service
    - EMAIL=your@email
    - CRON_TIME=0 2,14 * * *
    - AWS_ACCESS_KEY_ID=XXX
    - AWS_SECRET_ACCESS_KEY=YYY
    - AWS_DEFAULT_REGION=ZZZ
  deploy:
    restart_policy:
      condition: on-failure
    placement:
      constraints:
        - node.role == manager
      
```

If you are running the container independently, the whole command would look 
something like this:
```
docker run -it --rm --name certbot \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
-v "/var/run/docker.sock:/var/run/docker.sock" \
-e "DOMAINS=sub1.domain1.com,sub2.domain1.com,domain2.org,sub.domain3.net" \
-e "NGINX_SERVICE_NAME=my_nginx_service" \
-e "EMAIL=your@email" \
-e "CRON_TIME=0 2,14 * * *" \
-e "AWS_ACCESS_KEY_ID=<XXX>" \
-e "AWS_SECRET_ACCESS_KEY=<YYY>" \
-e "AWS_DEFAULT_REGION=<ZZZ>"
auto-docker-letsencrypt \
/usr/local/bin/pipenv run certbot certonly --dns-route53 --agree-tos -n \
--agree-tos --email your@email \
--domains sub1.domain1.com,sub2.domain1.com,domain2.org,sub.domain3.net \
--post-hook '/usr/bin/python3 /auto-docker-letsencrypt/restart-nginx.py nginx'
```
