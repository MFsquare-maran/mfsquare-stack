# nginx liefert die Seite aus dem Volume aus (Inhalt legt der Provisioner an).
FROM nginx:1.27-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
