#!/usr/bin/env bash

DOCKER_IMAGE_PREFIX="ivanfranchin"
APP_NAME="book-service"
APP_VERSION="1.0.0"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_PREFIX}/${APP_NAME}:${APP_VERSION}"
SKIP_TESTS="true"

## -- Paketo Buildpacks
#if [ "$1" = "native" ];
#then
#  ./mvnw -Pnative clean spring-boot:build-image --projects "$APP_NAME" -DskipTests="$SKIP_TESTS" -Dspring-boot.build-image.imageName="$DOCKER_IMAGE_NAME"
#else
#  ./mvnw clean spring-boot:build-image --projects "$APP_NAME" -DskipTests="$SKIP_TESTS" -Dspring-boot.build-image.imageName="$DOCKER_IMAGE_NAME"
#fi

## -- Jib
./mvnw clean compile jib:dockerBuild \
  --projects "$APP_NAME" \
  -DskipTests="$SKIP_TESTS" \
  -Dimage="$DOCKER_IMAGE_NAME"