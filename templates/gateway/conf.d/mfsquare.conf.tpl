# HTTPS macht der Nginx Proxy Manager davor. Hier läuft alles über HTTP;
# die "https"-Header setzen wir fest, weil TLS immer am NPM endet.

# ---- 1) Authelia-Login-Portal (öffentlich, im MFsquare-Look) --------
server {
    listen 80;
    server_name ${AUTH_HOST};

    location = /mfsquare-theme.css {
        default_type text/css;
        alias /etc/nginx/mfsquare/theme/mfsquare-theme.css;
    }

    location / {
        proxy_pass http://authelia:9091;

        # WICHTIG: diese Header MÜSSEN in der location stehen. Sobald hier ein
        # proxy_set_header vorkommt, erbt nginx KEINE Header aus dem server-Block
        # mehr – dann käme bei Authelia der interne Host "authelia:9091" an und
        # /api/state schlägt mit "no cookie domain matches" fehl.
        proxy_set_header Host              $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-For   $remote_addr;
        proxy_set_header X-Forwarded-Uri   $request_uri;
        proxy_set_header Accept-Encoding "";

        sub_filter_once on;
        sub_filter '</head>' '<link rel="stylesheet" href="/mfsquare-theme.css"></head>';

        # Falls das CSS wegen strenger CSP nicht greift, diese zwei Zeilen aktivieren:
        # proxy_hide_header Content-Security-Policy;
        # add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; font-src 'self' data:; connect-src 'self'" always;
    }
}

# ---- 2) Dashboard (geschützt durch Authelia) ------------------------
server {
    listen 80;
    server_name ${DASHBOARD_HOST};

    set $target_url https://$host$request_uri;

    include /etc/nginx/mfsquare/snippets/authelia-location.conf;

    location / {
        include /etc/nginx/mfsquare/snippets/authelia-authrequest.conf;

        root /etc/nginx/mfsquare/dashboard;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
}
