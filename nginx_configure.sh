#!/usr/bin/env bash

NGINX_CONF_PATH='/etc/nginx'
GIT_REPO=https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master
set -e

cd $NGINX_CONF_PATH

if [ -f /etc/nginx/includes/upload_handler.conf ]; then
    mv /etc/nginx/includes/upload_handler.conf /etc/nginx/includes/upload_handler.conf.bak
fi

if [ -f /etc/nginx/nginx.conf ]; then
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi

if [ -f /etc/nginx/sites-available/upload ]; then
    mv /etc/nginx/sites-available/upload /etc/nginx/sites-available/upload.bak
fi

rm -rf $NGINX_CONF_PATH/setup
mkdir -p $NGINX_CONF_PATH/setup
cd $NGINX_CONF_PATH/setup
wget https://github.com/emawind84/nginx-upload-handler-conf/releases/download/v1/nginx-conf.tar.bz2
tar -xvf nginx-conf.tar.bz2 && rm nginx-conf.tar.bz2
chown -R root:root $NGINX_CONF_PATH/setup
cp -r $NGINX_CONF_PATH/setup/* $NGINX_CONF_PATH

echo "Downloading php file..."
wget $GIT_REPO/www/fileinfo.php -O www/fileinfo.php

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

if [ ! -f /etc/init.d/nginx ]; then
    echo "Creating init script..."
    cp $NGINX_CONF_PATH/setup/extra/nginx /etc/init.d/nginx
    chmod u+x /etc/init.d/nginx
    
    if command -v chkconfig ; then
        chkconfig --add /etc/init.d/nginx
        chkconfig --level 345 nginx on
    fi
    
    if command -v update-rc.d ; then
        update-rc.d -f nginx defaults
    fi
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
dd if=/dev/zero of=/tmp/test.tmp bs=512k count=1 >/dev/null 2>&1
curl --user ngxupload:ngxupload --data-binary '@/tmp/test.tmp' http://127.0.0.1:8180/upload 2>&1

# remove the setup folder
rm -rf $NGINX_CONF_PATH/setup

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
