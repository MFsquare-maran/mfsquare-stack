# ---- 1) Authelia-Login-Portal (im MFsquare-Look) --------
server {
    listen 80;
    server_name ${AUTH_HOST};

    location = /mfsquare-theme.css {
        default_type text/css;
        alias /etc/nginx/mfsquare/theme/mfsquare-theme.css;
    }

    location / {
        proxy_pass http://authelia:9091;

        proxy_set_header Host              $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header X-Forwarded-For   $remote_addr;
        proxy_set_header X-Forwarded-Uri   $request_uri;
        proxy_set_header Accept-Encoding "";

        sub_filter_once on;
        sub_filter '</head>' '<link rel="stylesheet" href="/mfsquare-theme.css"></head>';
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
