#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "WARNING: BOOK_SERVICE_CLIENT_SECRET must be informed as 1st parameter"
  exit 1
fi

BOOK_SERVICE_CLIENT_SECRET=$1

KEYCLOAK_HOST=${2:-keycloak}
KEYCLOAK_PORT=${3:-8080}
KEYCLOAK_HOST_PORT="$KEYCLOAK_HOST:$KEYCLOAK_PORT"

MY_ACCESS_TOKEN_FULL=$(
  docker exec -t -e CLIENT_SECRET=$BOOK_SERVICE_CLIENT_SECRET -e KEYCLOAK_HOST_PORT=$KEYCLOAK_HOST_PORT keycloak bash -c '
    curl -s -X POST \
    http://$KEYCLOAK_HOST_PORT/auth/realms/company-services/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=ivan.franchin" \
    -d "password=123" \
    -d "grant_type=password" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "client_id=book-service"
  ')

MY_ACCESS_TOKEN=$(echo $MY_ACCESS_TOKEN_FULL | jq -r .access_token)
echo "$MY_ACCESS_TOKEN"
