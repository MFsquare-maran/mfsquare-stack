# Provisioner-Image: rendert Config in die Volumes und beendet sich.
# nginx:alpine bringt sh, cp und envsubst bereits mit.
FROM nginx:1.27-alpine
WORKDIR /src
COPY templates ./templates
COPY assets ./assets
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
