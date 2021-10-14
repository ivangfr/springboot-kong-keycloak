#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "WARNING: BOOK_SERVICE_CLIENT_SECRET must be informed as 1st parameter"
  exit 1
fi

BOOK_SERVICE_CLIENT_SECRET=$1
KEYCLOAK_HOST_PORT=${2:-"keycloak:8080"}

MY_ACCESS_TOKEN_FULL=$(
  docker exec -t keycloak bash -c '
    curl -s -X POST \
    http://'$KEYCLOAK_HOST_PORT'/auth/realms/company-services/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=ivan.franchin" \
    -d "password=123" \
    -d "grant_type=password" \
    -d "client_secret='$BOOK_SERVICE_CLIENT_SECRET'" \
    -d "client_id=book-service"
  ')

MY_ACCESS_TOKEN=$(echo $MY_ACCESS_TOKEN_FULL | jq -r .access_token)
echo $MY_ACCESS_TOKEN
