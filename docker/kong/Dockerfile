FROM kong:2.8.3

LABEL maintainer="ivangfr@yahoo.com.br" description="Kong 2.8.3 + kong-oidc plugin"

USER root

RUN luarocks install kong-oidc

USER kong
