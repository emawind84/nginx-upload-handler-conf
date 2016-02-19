#!/usr/bin/env bash

NGINX_CONF_PATH='/etc/nginx'

set -e

cd $NGINX_CONF_PATH

if [ ! -d "includes" ]; then
  mkdir includes
fi

if [ ! -d "sites-available" ]; then
  mkdir sites-available
fi

if [ ! -d "sites-enabled" ]; then
  mkdir sites-enabled
fi

if [ ! -f /etc/nginx/includes/upload_handler.conf ]; then
    echo "File not found!"
    # download upload handler conf
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/includes/upload_handler.conf \
    -O includes/upload_handler.conf
fi

if [ ! -f /etc/nginx/nginx.conf ]; then
    # download default nginx conf
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/nginx.conf \
    -O /etc/nginx/nginx.conf
fi

if [ ! -f /etc/nginx/sites-available/upload ]; then
    # download upload server conf
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/sites-available/upload \
    -O /etc/nginx/sites-available/upload
fi

if [ ! -f /etc/nginx/sites-enabled/upload ]; then
    # create link for upload handler
    ln -s /etc/nginx/sites-available/upload /etc/nginx/sites-enabled/upload
fi

if [ $(cat /etc/passwd | grep www-data | wc -l) == 0 ]; then
    useradd -M www-data
    usermod -Ls /bin/false www-data
fi

nginx -t

if [ $? -eq 1 ]; then
    exit 1
fi

if [ $(ps -ef | grep -v grep | grep nginx | wc -l) == 0 ]; then
    echo "Starting nginx server..."
    nginx
fi

dd if=/dev/zero of=/tmp/temp.tmp bs=512k count=1 >/dev/null 2>&1
curl --data-binary '@/tmp/test.tmp' http://127.0.0.1:8180/upload >/dev/null 2>&1

if [ $? -eq 1 ]; then
    exit 1
fi

echo 'https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/'
echo 'Start nginx using: nginx'
echo 'Reload nginx using: nginx -s reload'
echo 'Stop nginx using: nginx -s stop'

exit $?
