#!/bin/sh
# =====================================================================
#  MFsquare Provisioner
#  Rendert die Templates mit deinen Umgebungsvariablen in die Volumes.
#  WICHTIG: envsubst ersetzt NUR die ausdrücklich gelisteten Variablen,
#  damit nginx-eigene $variablen ($host, $target_url, …) erhalten bleiben.
# =====================================================================
set -eu

AUTH_OUT=/out/authelia
GW_OUT=/out/gateway

echo "MFsquare provisioner: rendere Konfiguration ..."
mkdir -p "$AUTH_OUT/assets" "$GW_OUT/conf.d" "$GW_OUT/snippets" "$GW_OUT/theme" "$GW_OUT/dashboard"

# ---- Authelia ----
envsubst '${DOMAIN} ${DASHBOARD_HOST} ${AUTH_HOST} ${SESSION_SECRET} ${JWT_SECRET} ${STORAGE_ENCRYPTION_KEY} ${SESSION_EXPIRATION} ${SESSION_INACTIVITY} ${LOG_LEVEL}' \
  < templates/authelia/configuration.yml.tpl > "$AUTH_OUT/configuration.yml"

envsubst '${ADMIN_USER} ${ADMIN_DISPLAYNAME} ${ADMIN_EMAIL}' \
  < templates/authelia/users_database.yml.tpl > "$AUTH_OUT/users_database.yml"

# Passwort-Hash NICHT durch envsubst schicken (er enthält viele '$', die
# envsubst als Variablen missdeuten würde). Stattdessen den Platzhalter
# @@ADMIN_PASSWORD_HASH@@ literal ersetzen – egal wie viele '$' im Hash sind.
tmp_users="$AUTH_OUT/users_database.yml"
ADMIN_PASSWORD_HASH="${ADMIN_PASSWORD_HASH:-}" awk '
  BEGIN{ h=ENVIRON["ADMIN_PASSWORD_HASH"] }
  { gsub(/@@ADMIN_PASSWORD_HASH@@/, h); print }
' "$tmp_users" > "$tmp_users.new" && mv "$tmp_users.new" "$tmp_users"

cp assets/logo.png "$AUTH_OUT/assets/logo.png"

# ---- Gateway (nginx) ----
# Server-Blöcke: NUR Hostnamen ersetzen, nginx-$vars behalten:
envsubst '${DASHBOARD_HOST} ${AUTH_HOST}' \
  < templates/gateway/conf.d/mfsquare.conf.tpl > "$GW_OUT/conf.d/mfsquare.conf"

# Snippets:
cp templates/gateway/snippets/authelia-location.conf "$GW_OUT/snippets/authelia-location.conf"
envsubst '${AUTH_HOST}' \
  < templates/gateway/snippets/authelia-authrequest.conf.tpl > "$GW_OUT/snippets/authelia-authrequest.conf"

# Haupt-Config, Theme, Dashboard (unverändert kopieren):
cp templates/gateway/nginx.conf              "$GW_OUT/nginx.conf"
cp templates/gateway/theme/mfsquare-theme.css "$GW_OUT/theme/mfsquare-theme.css"
cp assets/dashboard/index.html               "$GW_OUT/dashboard/index.html"

echo "MFsquare provisioner: fertig."
