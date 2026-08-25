#!/bin/sh
# =====================================================================
#  MFsquare Dashboard – Provisioner
#  Legt die Startinhalte (services.yaml + bilder/) EINMALIG ins Volume,
#  wenn dort noch nichts liegt. Bestehende Dateien werden NIE überschrieben.
#  index.html wird bei JEDEM Start aktualisiert (kommt aus dem Git/Image).
# =====================================================================
set -eu

WEB=/web            # Zielvolume (liegt auf dem Server unter DATA_DIR/web)
SRC=/seed           # Startinhalte aus dem Image

mkdir -p "$WEB/bilder"

# index.html immer aktualisieren (Programmcode, nicht deine Daten):
cp "$SRC/index.html" "$WEB/index.html"

# services.yaml nur anlegen, wenn noch keine da ist:
if [ ! -f "$WEB/services.yaml" ]; then
  cp "$SRC/services.yaml" "$WEB/services.yaml"
  echo "provisioner: services.yaml angelegt."
else
  echo "provisioner: services.yaml existiert bereits – unverändert."
fi

# Beispielbilder / LIESMICH nur beim ersten Mal (wenn bilder/ leer ist):
if [ -z "$(ls -A "$WEB/bilder" 2>/dev/null)" ]; then
  cp -r "$SRC/bilder/." "$WEB/bilder/" 2>/dev/null || true
  echo "provisioner: bilder/ initialisiert."
else
  echo "provisioner: bilder/ vorhanden – unverändert."
fi

echo "provisioner: fertig."
