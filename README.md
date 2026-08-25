# MFsquare Dashboard – Portainer-Git-Stack (Weg C)

Ein nginx-Container liefert deine Seite aus. Die Inhalte liegen in einem
**Volume auf dem Server** unter `DATA_DIR/web`. Ein Provisioner legt die
Startinhalte beim ersten Start dorthin – danach bearbeitest du
`services.yaml` und die Bilder **direkt auf dem Server** und es ist
**sofort live, ohne Redeploy**.

## Struktur (im Git)
```
docker-compose.yml        ← Stack (Provisioner + nginx)
Dockerfile                ← nginx + Config
Dockerfile.provisioner    ← Startinhalte + Kopierskript
provision.sh              ← kopiert Startinhalte ins Volume (nur wenn leer)
nginx/default.conf        ← Auslieferung (services.yaml ohne Cache)
site/index.html           ← die Seite (wird bei jedem Deploy aktualisiert)
site/services.yaml        ← Startinhalt der Dienste
site/bilder/              ← Startbilder
```

## Ablage auf dem Server (Volume)
Wird automatisch unter `DATA_DIR/web` angelegt und enthält nach dem Start:
```
<DATA_DIR>/web/index.html      (wird bei jedem Deploy überschrieben)
<DATA_DIR>/web/services.yaml    ← HIER bearbeitest du die Dienste
<DATA_DIR>/web/bilder/          ← HIER legst du Bilder ab
```
Default `DATA_DIR = /home/maran/serverdata/server/network_dashboard`.

## Vor dem ersten Deploy: Ordner anlegen
```bash
mkdir -p /home/maran/serverdata/server/network_dashboard/web
```

## In Portainer deployen (Git)
1. Ordner ins Git-Repo pushen.
2. Portainer → **Stacks → Add stack → Repository**
   - Repository URL, Reference `refs/heads/main`, Compose path `docker-compose.yml`
3. **Environment variables:**
   - `DATA_DIR=/home/maran/serverdata/server/network_dashboard`
   - `WEB_PORT=8085` (optional)
4. **Deploy the stack.** (Provisioner läuft kurz, endet mit „Exited (0)";
   `mfsquare-dashboard` bleibt „Up".)

## Im Nginx Proxy Manager (Server A)
- Domain: `network.mfsquare.ch`, Scheme `http`
- Forward: `192.168.196.202` : `8085` (bzw. dein WEB_PORT)
- SSL-Zertifikat + „Force SSL"

## Dienste ändern (der bequeme Teil)
Direkt auf dem Server bearbeiten – **kein Redeploy nötig**:
```bash
nano /home/maran/serverdata/server/network_dashboard/web/services.yaml
# Bilder hierher:
# /home/maran/serverdata/server/network_dashboard/web/bilder/
```
Seite neu laden – fertig. (Ohne `bild:` wird automatisch das Favicon geladen.)

## Programm aktualisieren
Wenn du am `index.html` (Aussehen/Funktion) etwas änderst: im Git ändern,
pushen, in Portainer **„Pull and redeploy"**. Deine `services.yaml` und Bilder
im Volume bleiben dabei erhalten.

## Absicherung
Die Seite zeigt alle Adressen offen. Für öffentlichen Betrieb den
Reverse-Proxy davor schützen (NPM Access List oder Authelia). Im Projekt
selbst ist bewusst kein Login enthalten.
