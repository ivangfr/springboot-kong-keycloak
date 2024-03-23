#!/usr/bin/env bash

MYSQL_VERSION="8.3.0"
POSTGRES_VERSION="13.14"
MONGO_VERSION="7.0.6"
KEYCLOAK_VERSION="23.0.7"
KONG_VERSION="2.8.4"
BOOK_SERVICE_VERSION="1.0.0"

if [[ "$(docker images -q ivanfranchin/book-service:${BOOK_SERVICE_VERSION} 2> /dev/null)" == "" ]] ; then
  echo "[WARNING] Before initialize the environment, build the book-service Docker image: ./docker-build.sh [native]"
  exit 1
fi

source scripts/my-functions.sh

echo
echo "Starting environment"
echo "===================="

echo
echo "Creating network"
echo "----------------"
docker network create springboot-kong-keycloak-net

echo
echo "Starting keycloak-database"
echo "--------------------------"
docker run -d \
  --name keycloak-database \
  -e MYSQL_DATABASE=keycloak \
  -e MYSQL_USER=keycloak \
  -e MYSQL_PASSWORD=password \
  -e MYSQL_ROOT_PASSWORD=root_password \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="mysqladmin ping -u root -p$${MYSQL_ROOT_PASSWORD}" \
  mysql:${MYSQL_VERSION}

echo
echo "Starting kong-database"
echo "----------------------"
docker run -d \
  --name kong-database \
  -e POSTGRES_USER=kong \
  -e POSTGRES_PASSWORD=kong \
  -e POSTGRES_DB=kong \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="pg_isready -U postgres" \
  postgres:${POSTGRES_VERSION}

echo
echo "Starting mongodb"
echo "----------------"
docker run -d \
  --name mongodb \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="echo 'db.stats().ok' | mongosh localhost:27017/bookdb --quiet" \
  mongo:${MONGO_VERSION}

echo
wait_for_container_log "mongodb" "Waiting for connections"

echo
wait_for_container_log "kong-database" "port 5432"

echo
wait_for_container_log "keycloak-database" "port: 3306"

echo
echo "Starting keycloak"
echo "-----------------"
docker run -d \
  --name keycloak \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB=mysql \
  -e KC_DB_URL_HOST=keycloak-database \
  -e KC_DB_URL_DATABASE=keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=password \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="curl -f http://localhost:8080/health/ready || exit 1" \
  quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev

echo
echo "Starting book-service"
echo "---------------------"
docker run -d \
  --name book-service \
  -e MONGODB_HOST=mongodb \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  --health-cmd="curl -f http://localhost:9080/actuator/health || exit 1" \
  ivanfranchin/book-service:${BOOK_SERVICE_VERSION}

echo
echo "Running kong-database migration"
echo "-------------------------------"
docker run --rm \
  --name kong-database-migration \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-database" \
  -e "KONG_PG_PASSWORD=kong" \
  --network=springboot-kong-keycloak-net \
  kong:${KONG_VERSION} kong migrations bootstrap

if [[ "$(docker images -q kong:${KONG_VERSION}-oidc 2> /dev/null)" == "" ]]; then
  echo
  echo "Building kong docker image with kong-oidc plugin"
  echo "------------------------------------------------"
  docker build -t kong:${KONG_VERSION}-oidc docker/kong
fi

echo
echo "Starting kong"
echo "-------------"
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
  -e "KONG_PLUGINS=bundled,oidc" \
  --restart=unless-stopped \
  --network=springboot-kong-keycloak-net \
  kong:${KONG_VERSION}-oidc

echo
wait_for_container_log "kong" "finished preloading"

echo
wait_for_container_log "book-service" "Started"

echo
wait_for_container_log "keycloak" "started in"

echo
echo "Environment Up and Running"
echo "=========================="
echo