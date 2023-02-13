#!/usr/bin/env bash

if [ "$1" = "native" ];
then
  ./mvnw clean -Pnative spring-boot:build-image --projects book-service -DskipTests
else
  ./mvnw clean compile jib:dockerBuild --projects book-service
fi
