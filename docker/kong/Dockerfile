FROM kong:2.7.0-centos

LABEL maintainer="ivangfr@yahoo.com.br" description="Kong 2.7.0-centos + kong-oidc plugin"

USER root

RUN luarocks install kong-oidc

USER kong
