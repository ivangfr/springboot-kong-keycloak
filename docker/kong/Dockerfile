FROM kong:2.6.0-centos

LABEL maintainer="ivangfr@yahoo.com.br" description="Kong 2.6.0-centos + kong-oidc plugin"

USER root

RUN yum install -y git unzip && yum clean all

RUN luarocks install kong-oidc

USER kong
