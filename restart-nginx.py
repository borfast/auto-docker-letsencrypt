#!/usr/bin/python3
import subprocess
import sys

import docker

nginx_service_name = sys.argv[1]

client = docker.from_env()

services = client.services.list()

for service in services:
    name = service.name.split('.')
    if nginx_service_name == name[0]:
        service.reload()
        subprocess.run(['docker', 'service', 'update', nginx_service_name, '--force'])
        break
