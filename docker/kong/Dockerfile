FROM kong:2.8.4

LABEL maintainer="ivangfr@yahoo.com.br" description="Kong 2.8.4 + kong-oidc plugin"

USER root

RUN luarocks install kong-oidc

USER kong
