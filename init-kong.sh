#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "WARNING: BOOK_SERVICE_CLIENT_SECRET must be informed as 1st parameter"
  exit 1
fi

BOOK_SERVICE_CLIENT_SECRET=$1
KONG_ADMIN_HOST_PORT=${2:-"localhost:8001"}
KEYCLOAK_HOST_PORT=${3:-"keycloak:8080"}
BOOK_SERVICE_HOST_PORT=${4:-"book-service:9080"}

echo
echo "BOOK_SERVICE_CLIENT_SECRET: $BOOK_SERVICE_CLIENT_SECRET"
echo "KONG_ADMIN_HOST_PORT: $KONG_ADMIN_HOST_PORT"
echo "KEYCLOAK_HOST_PORT: $KEYCLOAK_HOST_PORT"

echo
echo "Add service"
echo "-----------"

curl -i -X POST "http://$KONG_ADMIN_HOST_PORT/services/" \
  -d "name=book-service" \
  -d "url=http://$BOOK_SERVICE_HOST_PORT"

echo
echo "Add Public Route to Service"
echo "---------------------------"

curl -i -X POST "http://$KONG_ADMIN_HOST_PORT/services/book-service/routes/" \
  -d "name=book-service-public" \
  -d "protocols[]=http" \
  -d "paths[]=/actuator" \
  -d "hosts[]=book-service" \
  -d "strip_path=false"

echo
echo "Add Private Route to Service"
echo "----------------------------"

curl -i -X POST "http://$KONG_ADMIN_HOST_PORT/services/book-service/routes/" \
  -d "name=book-service-private" \
  -d "protocols[]=http" \
  -d "paths[]=/api" \
  -d "hosts[]=book-service" \
  -d "strip_path=false"

echo
echo "Add kong-oidc Plugin to Private Route"
echo "-------------------------------------"

BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID=$(curl -s -X POST "http://$KONG_ADMIN_HOST_PORT/routes/book-service-private/plugins" \
  -d "name=oidc" \
  -d "config.client_id=book-service" \
  -d "config.bearer_only=yes" \
  -d "config.client_secret=$BOOK_SERVICE_CLIENT_SECRET" \
  -d "config.realm=company-services" \
  -d "config.introspection_endpoint=http://$KEYCLOAK_HOST_PORT/realms/company-services/protocol/openid-connect/token/introspect" \
  -d "config.discovery=http://$KEYCLOAK_HOST_PORT/realms/company-services/.well-known/openid-configuration" | jq -r '.id')

echo "BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID=$BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID"

echo
echo "Add Serverless Function (post-function) to Private Route"
echo "--------------------------------------------------------"

BOOK_SERVICE_PRIVATE_ROUTE_SERVERLESS_FUNCTION_ID=$(curl -s -X POST "http://$KONG_ADMIN_HOST_PORT/routes/book-service-private/plugins" \
  -F "name=post-function" \
  -F "config.access[1]=@kong/serverless/extract-username.lua" | jq -r '.id')

echo "BOOK_SERVICE_PRIVATE_ROUTE_SERVERLESS_FUNCTION_ID=$BOOK_SERVICE_PRIVATE_ROUTE_SERVERLESS_FUNCTION_ID"

echo
echo "===================="
echo "                          List services: curl -i http://$KONG_ADMIN_HOST_PORT/services"
echo "               List book-service routes: curl -i http://$KONG_ADMIN_HOST_PORT/services/book-service/routes"
echo "List book-service private route plugins: curl -i http://$KONG_ADMIN_HOST_PORT/routes/book-service-private/plugins"
echo "...................."
echo "Delete all book-service configuration: "
echo " curl -i -X DELETE http://$KONG_ADMIN_HOST_PORT/routes/book-service-private/plugins/$BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID"
echo " curl -i -X DELETE http://$KONG_ADMIN_HOST_PORT/routes/book-service-private/plugins/$BOOK_SERVICE_PRIVATE_ROUTE_SERVERLESS_FUNCTION_ID"
echo " curl -i -X DELETE http://$KONG_ADMIN_HOST_PORT/services/book-service/routes/book-service-private"
echo " curl -i -X DELETE http://$KONG_ADMIN_HOST_PORT/services/book-service/routes/book-service-public"
echo " curl -i -X DELETE http://$KONG_ADMIN_HOST_PORT/services/book-service"
echo "===================="
echo
