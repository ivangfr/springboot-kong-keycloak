#!/usr/bin/env bash

echo
echo "Starting the environment shutdown"
echo "================================="

echo
echo "Removing containers"
echo "-------------------"
docker rm -fv book-service mongodb keycloak keycloak-database kong kong-database

echo
echo "Removing network"
echo "----------------"
docker network rm springboot-kong-keycloak-net

echo
echo "Environment shutdown successfully"
echo "================================="
echo
