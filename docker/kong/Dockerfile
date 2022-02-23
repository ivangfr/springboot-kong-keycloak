FROM kong:2.7.1-centos

LABEL maintainer="ivangfr@yahoo.com.br" description="Kong 2.7.1-centos + kong-oidc plugin"

USER root

RUN luarocks install kong-oidc

USER kong
