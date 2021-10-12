#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "WARNING: BOOK_SERVICE_CLIENT_SECRET must be informed as 1st parameter"
  exit 1
fi

BOOK_SERVICE_CLIENT_SECRET="$1"

KEYCLOAK_HOST=${2:-keycloak}
KEYCLOAK_PORT=${3:-8080}
KEYCLOAK_HOST_PORT="$KEYCLOAK_HOST:$KEYCLOAK_PORT"

echo
echo "BOOK_SERVICE_CLIENT_SECRET: $BOOK_SERVICE_CLIENT_SECRET"
echo "KEYCLOAK_HOST_PORT: $KEYCLOAK_HOST_PORT"

echo
echo "Add service"
echo "-----------"

BOOK_SERVICE_SERVICE_ID=$(curl -s -X POST http://localhost:8001/services/ \
  -d "name=book-service" \
  -d "protocol=http" \
  -d "host=book-service" \
  -d "port=9080" | jq -r '.id')

echo "BOOK_SERVICE_SERVICE_ID=$BOOK_SERVICE_SERVICE_ID"

echo
echo "Add Public Route to Service"
echo "---------------------------"

BOOK_SERVICE_PUBLIC_ROUTE_ID=$(curl -s -X POST http://localhost:8001/services/book-service/routes/ \
  -d "protocols[]=http" \
  -d "paths[]=/actuator" \
  -d "hosts[]=book-service" \
  -d "strip_path=false" | jq -r '.id')

echo "BOOK_SERVICE_PUBLIC_ROUTE_ID=$BOOK_SERVICE_PUBLIC_ROUTE_ID"

echo
echo "Add Private Route to Service"
echo "----------------------------"

BOOK_SERVICE_PRIVATE_ROUTE_ID=$(curl -s -X POST http://localhost:8001/services/book-service/routes/ \
  -d "protocols[]=http" \
  -d "paths[]=/api" \
  -d "hosts[]=book-service" \
  -d "strip_path=false" | jq -r '.id')

echo "BOOK_SERVICE_PRIVATE_ROUTE_ID=$BOOK_SERVICE_PRIVATE_ROUTE_ID"

echo
echo "Add kong-oidc plugin to Private Route"
echo "-------------------------------------"

BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID=$(curl -s -X POST http://localhost:8001/routes/$BOOK_SERVICE_PRIVATE_ROUTE_ID/plugins \
  -d "name=oidc" \
  -d "config.client_id=book-service" \
  -d "config.bearer_only=yes" \
  -d "config.client_secret=${BOOK_SERVICE_CLIENT_SECRET}" \
  -d "config.realm=company-services" \
  -d "config.introspection_endpoint=http://${KEYCLOAK_HOST_PORT}/auth/realms/company-services/protocol/openid-connect/token/introspect" \
  -d "config.discovery=http://${KEYCLOAK_HOST_PORT}/auth/realms/company-services/.well-known/openid-configuration" | python -mjson.tool | jq -r '.id')

echo "BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID=$BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID"

echo
echo "===================="
echo " To list services: curl http://localhost:8001/services"
echo " To list book-service routes: curl http://localhost:8001/services/book-service/routes"
echo " To list book-service private route plugins: curl http://localhost:8001/routes/$BOOK_SERVICE_PRIVATE_ROUTE_ID/plugins"
echo "...................."
echo " To delete all configuration: "
echo " curl -X DELETE http://localhost:8001/routes/$BOOK_SERVICE_PRIVATE_ROUTE_ID/plugins/$BOOK_SERVICE_PRIVATE_ROUTE_KONG_OIDC_PLUGIN_ID"
echo " curl -X DELETE http://localhost:8001/services/book-service/routes/$BOOK_SERVICE_PRIVATE_ROUTE_ID"
echo " curl -X DELETE http://localhost:8001/services/book-service/routes/$BOOK_SERVICE_PUBLIC_ROUTE_ID"
echo " curl -X DELETE http://localhost:8001/services/$BOOK_SERVICE_SERVICE_ID"
echo "===================="
echo
