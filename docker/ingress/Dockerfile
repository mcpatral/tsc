ARG VERSION=v1.10.0

FROM registry.k8s.io/ingress-nginx/controller:${VERSION}
USER root

RUN apk update
RUN apk upgrade 
USER www-data