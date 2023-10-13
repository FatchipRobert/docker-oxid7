# Docker setup for Oxid 7

This Docker setup installs a Oxid 7 shop with demodata.

## Important URLs
Shop: https://localhost  
Admin: https://localhost/admin (Login:  admin@admin.de // admin12)  
phpmyadmin: http://localhost:8080/ (Login: docker // docker)  
SSH/SFTP: root@localhost Port: 2222 (Login: docker)

## Docker setup

### create container
docker-compose build
### fire up container
docker-compose up -d