#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "WARNING: BOOK_SERVICE_CLIENT_SECRET must be informed as 1st parameter"
  exit 1
fi

if [ -z "$2" ]; then
  echo "WARNING: HOST_IP must be informed as 2nd parameter"
  exit 1
fi

BOOK_SERVICE_CLIENT_SECRET="$1"
HOST_IP="$2"
BEARER_ONLY=${3:-"yes"}

echo
echo "BOOK_SERVICE_CLIENT_SECRET: $BOOK_SERVICE_CLIENT_SECRET"
echo "HOST_IP: $HOST_IP"

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
echo "Add Route to Service"
echo "--------------------"

BOOK_SERVICE_ROUTE_ID=$(curl -s -X POST http://localhost:8001/services/book-service/routes/ \
  -d "protocols[]=http" \
  -d "paths[]=/book-service" | jq -r '.id')

echo "BOOK_SERVICE_ROUTE_ID=$BOOK_SERVICE_ROUTE_ID"

echo
echo "Add kong-oidc plugin to route"
echo "-----------------------------"

BOOK_SERVICE_ROUTE_KONG_OIDC_PLUGIN_ID=$(curl -s -X POST http://localhost:8001/routes/$BOOK_SERVICE_ROUTE_ID/plugins \
  -d "name=oidc" \
  -d "config.client_id=book-service" \
  -d "config.bearer_only=${BEARER_ONLY}" \
  -d "config.client_secret=${BOOK_SERVICE_CLIENT_SECRET}" \
  -d "config.realm=company-services" \
  -d "config.introspection_endpoint=http://${HOST_IP}:8080/auth/realms/company-services/protocol/openid-connect/token/introspect" \
  -d "config.discovery=http://${HOST_IP}:8080/auth/realms/company-services/.well-known/openid-configuration" | python -mjson.tool | jq -r '.id')

echo "BOOK_SERVICE_ROUTE_KONG_OIDC_PLUGIN_ID=$BOOK_SERVICE_ROUTE_KONG_OIDC_PLUGIN_ID"

echo
echo "===================="
echo " To list services: curl http://localhost:8001/services"
echo "   To list routes: curl http://localhost:8001/services/book-service/routes"
echo "  To list plugins: curl http://localhost:8001/routes/$BOOK_SERVICE_ROUTE_ID/plugins"
echo "...................."
echo " To delete all configuration: "
echo " curl -X DELETE http://localhost:8001/routes/$BOOK_SERVICE_ROUTE_ID/plugins/$BOOK_SERVICE_ROUTE_KONG_OIDC_PLUGIN_ID"
echo " curl -X DELETE http://localhost:8001/services/book-service/routes/$BOOK_SERVICE_ROUTE_ID"
echo " curl -X DELETE http://localhost:8001/services/$BOOK_SERVICE_SERVICE_ID"
echo "===================="
echo
