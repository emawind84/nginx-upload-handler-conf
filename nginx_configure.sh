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
    echo "Downloading upload_handler.conf..."
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/includes/upload_handler.conf \
    -O includes/upload_handler.conf
fi

if [ ! -f /etc/nginx/nginx.conf ]; then
    echo "Downloading nginx.conf..."
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/nginx.conf \
    -O /etc/nginx/nginx.conf
fi

if [ ! -f /etc/nginx/sites-available/upload ]; then
    echo "Downloading upload config file..."    
    wget https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master/sites-available/upload \
    -O /etc/nginx/sites-available/upload
fi

if [ ! -f /etc/nginx/sites-enabled/upload ]; then
    echo "Creating link for upload file"
    ln -s /etc/nginx/sites-available/upload /etc/nginx/sites-enabled/upload
fi

if [ $(cat /etc/passwd | grep www-data | wc -l) == 0 ]; then
    echo "Creating user www-data..."
    useradd -M www-data
    usermod -Ls /bin/false www-data
fi

if command -v htpasswd >/dev/null 2>&1; then
    echo 'Generating basic authentication user...'
    htpasswd -b -c /etc/nginx/.htpasswd.upload ngxupload ngxupload
else
    echo 'htpasswd command not present, cannot generate basic auth user'
    exit 1
fi

echo "Checking nginx configuration..."
nginx -t

if [ $? -eq 1 ]; then
    exit 1
fi

if [ $(ps -ef | grep -v grep | grep nginx | wc -l) == 0 ]; then
    echo "Starting nginx server..."
    nginx
else
    echo "Reloading nginx configuration..."
    nginx -s reload
fi

# test upload request
echo "Testing file upload..."
dd if=/dev/zero of=/tmp/temp.tmp bs=512k count=1 >/dev/null 2>&1
curl --user ngxupload:ngxupload --data-binary '@/tmp/test.tmp' http://127.0.0.1:8180/upload >/dev/null 2>&1

if [ $? -eq 1 ]; then
    exit 1
fi

echo "-------------------------------------------------------------------------"
echo 'For more command line check this link:'
echo 'https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/'
echo "-------------------------------------------------------------------------"
echo 'Start nginx using: nginx'
echo 'Reload nginx using: nginx -s reload'
echo 'Stop nginx using: nginx -s stop'

exit $?