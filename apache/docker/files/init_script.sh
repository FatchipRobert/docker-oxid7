#!/usr/bin/env bash
set -e

echo "Restart ssh server"
/etc/init.d/ssh restart

CONTAINER_FIRST_STARTUP="CONTAINER_FIRST_STARTUP"
if [ ! -e /$CONTAINER_FIRST_STARTUP ];
then
    touch /$CONTAINER_FIRST_STARTUP

    while ! mysqladmin ping -h"mysql.$DOMAIN" --silent; do
        sleep 1
        echo "Waiting for MYSQL server"
    done

    echo "MYSQL SERVER IS UP!"

    php /var/www/html/vendor/bin/oe-console oe:setup:shop --db-host=mysql.localhost --db-port=3306 --db-name=$MYSQL_DATABASE --db-user=$MYSQL_USER --db-password=$MYSQL_PASSWORD --shop-url=https://$DOMAIN --shop-directory=/var/www/html/source --compile-directory=/var/www/html/source/tmp --language=de
    php /var/www/html/vendor/bin/oe-console oe:setup:demodata
    php /var/www/html/vendor/bin/oe-console oe:admin:create-user --admin-email=$OXID_ADMIN_USER --admin-password=$OXID_ADMIN_PASSWORD

    composer require oxid-esales/developer-tools
    vendor/bin/oe-console oe:theme:activate apex
fi

echo "#####################################"
echo "###### Docker setup completed! ######"
echo "#####################################"

exec "$@"