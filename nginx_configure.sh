#!/usr/bin/env bash

NGINX_CONF_PATH='/etc/nginx'
GIT_REPO=https://raw.githubusercontent.com/emawind84/nginx-upload-handler-conf/master
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

if [ -f /etc/nginx/includes/upload_handler.conf ]; then
    mv /etc/nginx/includes/upload_handler.conf /etc/nginx/includes/upload_handler.conf.bak
fi

echo "Downloading upload_handler.conf..."
wget $GIT_REPO/includes/upload_handler.conf \
-O includes/upload_handler.conf

if [ -f /etc/nginx/nginx.conf ]; then
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi

echo "Downloading nginx.conf..."
wget $GIT_REPO/nginx.conf \
-O /etc/nginx/nginx.conf

if [ -f /etc/nginx/sites-available/upload ]; then
    mv /etc/nginx/sites-available/upload /etc/nginx/sites-available/upload.bak
fi

echo "Downloading upload config file..."    
wget $GIT_REPO/sites-available/upload \
-O /etc/nginx/sites-available/upload

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

if [ ! -f /etc/init.d/nginx ]; then
    echo "Creating init script..."
    wget $GIT_REPO/extra/nginx \
    -O /etc/init.d/nginx
    
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
