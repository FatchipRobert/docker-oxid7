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

    sudo -uwww-data php /var/www/html/vendor/bin/oe-console oe:setup:shop --db-host=mysql.$DOMAIN --db-port=3306 --db-name=$MYSQL_DATABASE --db-user=$MYSQL_USER --db-password=$MYSQL_PASSWORD --shop-url=https://$DOMAIN --shop-directory=/var/www/html/source --compile-directory=/var/www/html/source/tmp --language=de
    sudo -uwww-data php /var/www/html/vendor/bin/oe-console oe:setup:demodata
    sudo -uwww-data php /var/www/html/vendor/bin/oe-console oe:admin:create-user --admin-email=$OXID_ADMIN_USER --admin-password=$OXID_ADMIN_PASSWORD

    sudo -uwww-data composer require oxid-esales/developer-tools
    sudo -uwww-data vendor/bin/oe-console oe:theme:activate apex
    
    sudo -uwww-data mkdir -p /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/
    sudo -uwww-data git clone https://github.com/FatchipRobert/paypal-module.git --branch Oxid7 /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/
    sudo -uwww-data sed -i 's/catalysts\/paypal-module/catalysts-dev\/paypal-module/g' /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/composer.json
    
    sudo -uwww-data cp /unittesting/config.inc.TEST.php /var/www/html/source/config.inc.TEST.php    
    sudo -uwww-data cat /unittesting/config.inc.php_addToEnd >> /var/www/html/source/config.inc.php
     
    sudo -uwww-data cp /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/tests/.env.dist /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/tests/.env
    sudo -uwww-data cp /unittesting/composer.json /var/www/html/composer.json
    sudo -uwww-data cp /unittesting/test_config.yml /var/www/html/test_config.yml
    
    cd /var/www/html/
    sudo -uwww-data composer update -n
    
    sudo -uwww-data vendor/bin/oe-console oe:module:activate osc_paypal
    
    echo "CREATE DATABASE $MYSQL_DATABASE_TEST;" | mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD --host=mysql.$DOMAIN
    mysqldump -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD --host=mysql.$DOMAIN $MYSQL_DATABASE | mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD --host=mysql.$DOMAIN $MYSQL_DATABASE_TEST
    
    sudo -uwww-data php vendor/bin/runtests /var/www/html/vendor/oxid-solution-catalysts-dev/paypal-module/tests/
fi

echo "#####################################"
echo "###### Docker setup completed! ######"
echo "#####################################"

exec "$@"