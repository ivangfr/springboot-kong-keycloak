#!/usr/bin/env bash

echo "Creating network"
docker network create springboot-kong-keycloak-net

echo "Starting mongodb"
docker run -d \
  --name mongodb \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="echo 'db.stats().ok' | mongo localhost:27017/bookdb --quiet" \
  mongo:5.0.3

echo "Starting keycloak-database"
docker run -d \
  --name keycloak-database \
  -e MYSQL_DATABASE=keycloak \
  -e MYSQL_USER=keycloak \
  -e MYSQL_PASSWORD=password \
  -e MYSQL_ROOT_PASSWORD=root_password \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="mysqladmin ping -u root -p$${MYSQL_ROOT_PASSWORD}" \
  mysql:5.7.35

echo "Starting kong-database"
docker run -d \
  --name kong-database \
  -e POSTGRES_USER=kong \
  -e POSTGRES_PASSWORD=kong \
  -e POSTGRES_DB=kong \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="pg_isready -U postgres" \
  postgres:13.4

sleep 5

echo "Starting keycloak"
docker run -d \
  --name keycloak \
  -p 8080:8080 \
  -e KEYCLOAK_USER=admin \
  -e KEYCLOAK_PASSWORD=admin \
  -e DB_VENDOR=mysql \
  -e DB_ADDR=keycloak-database \
  -e DB_USER=keycloak \
  -e DB_PASSWORD=password \
  -e JDBC_PARAMS=useSSL=false \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="curl -f http://localhost:8080/auth || exit 1" \
  jboss/keycloak:15.0.2

echo "Starting book-service"
docker run -d \
  --name book-service \
  -e MONGODB_HOST=mongodb \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="curl -f http://localhost:9080/actuator/health || exit 1" \
  ivanfranchin/book-service:1.0.0

echo "Running kong-database migration"
docker run --rm \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-database" \
  -e "KONG_PG_PASSWORD=kong" \
  --network=springboot-kong-keycloak-net \
  kong:2.6.0-centos kong migrations bootstrap

sleep 3

echo "Starting kong"
docker run -d \
  --name kong \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-database" \
  -e "KONG_PG_PASSWORD=kong" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_LISTEN_SSL=0.0.0.0:8444" \
  -e "KONG_PLUGINS=oidc" \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  kong:2.6.0-centos-oidc

echo "-------------------------------------------"
echo "Containers started!"
echo "Press 'q' to stop and remove all containers"
echo "-------------------------------------------"
while true; do
    # In the following line -t for timeout, -N for just 1 character
    read -t 0.25 -N 1 input
    if [[ ${input} = "q" ]] || [[ ${input} = "Q" ]]; then
        echo
        break
    fi
done

echo "Removing containers"
docker rm -fv book-service mongodb keycloak keycloak-database kong kong-database

echo "Removing network"
docker network rm springboot-kong-keycloak-net
