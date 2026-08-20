# MFsquare – Login-Gateway als Portainer-Stack (Git-Deploy)

Echter Login **vor** dem Dashboard, im MFsquare-Aurora-Look – **kein Browser-Popup**.
Alles läuft über **Docker Compose** und wird in **Portainer** als **Git-Stack** deployt.
**Einstellungen** machst du zentral über **Environment variables** – **kein SSH nötig**.

```
Server A (192.168.196.190)            Server B (192.168.196.202)
┌───────────────────────┐   LAN       ┌──────────────────────────────────┐
│ Nginx Proxy Manager   │──:8082────▶ │ gateway ─▶ Dashboard (geschützt) │
│ (HTTPS, aussen)       │             │        └─▶ Authelia (Login)       │
└───────────────────────┘             └──────────────────────────────────┘
```
NPM läuft auf einem ANDEREN Server. Es erreicht das Gateway über die LAN-IP von
Server B + Port 8082. Deshalb kein gemeinsames Docker-Netz, sondern ein Host-Port.

## Wie funktioniert das ohne SSH?
Portainer klont beim Deploy das Repo. Ein kleiner **Provisioner-Container** wird aus dem
Repo gebaut, rendert deine Einstellungen (aus den Umgebungsvariablen) in **benannte Volumes**
und beendet sich. Erst danach starten Authelia und das Gateway. Dadurch brauchen wir keine
fragilen Bind-Mounts (die in Portainer-Git-Stacks Probleme machen) und keinen SSH-Zugriff.

---

## Einrichtung in Portainer

### 1) Repo bereitstellen
Diesen Ordner (`mfsquare-stack/`) in ein Git-Repo legen (GitHub/Gitea, öffentlich oder privat).

### 2) (entfällt) – NPM läuft auf einem anderen Server
Kein gemeinsames Docker-Netz nötig. Das Gateway veröffentlicht Port **8082** auf
Server B (192.168.196.202); der NPM auf Server A zeigt per LAN dorthin (Schritt 6).

### 3) Stack anlegen
Portainer → **Stacks → Add stack → Repository**.
- **Repository URL:** deine Repo-Adresse
- **Reference:** z. B. `refs/heads/main`
- **Compose path:** `docker-compose.yml`
- (Privates Repo: Authentication einschalten und Token hinterlegen.)

### 4) Environment variables setzen
Im selben Dialog unter **Environment variables** eintragen (alles Weitere nutzt Defaults):

| Name                  | Beispiel / Hinweis                                  |
|-----------------------|-----------------------------------------------------|
| `DOMAIN`              | `mfsquare.ch`                                        |
| `DASHBOARD_HOST`      | `network.mfsquare.ch`                                |
| `AUTH_HOST`           | `auth.mfsquare.ch`                                   |
| `ADMIN_EMAIL`         | `admin@mfsquare.ch`                                  |
| `ADMIN_PASSWORD_HASH` | Argon2-Hash (siehe Schritt 6) – **hier 1:1 einfügen** |
| `SESSION_SECRET`      | 64-stelliger Zufallswert (Schritt 6)                |
| `JWT_SECRET`          | 64-stelliger Zufallswert                            |
| `STORAGE_ENCRYPTION_KEY` | 64-stelliger Zufallswert                         |
| `GATEWAY_PORT`        | `8082` (Host-Port auf Server B)                     |

> In Portainers Env-Feld wird der Hash **wörtlich** übernommen – die `$`-Zeichen hier
> **nicht** verdoppeln. (Nur der Default im `docker-compose.yml` nutzt `$$`.)

### 5) **Deploy the stack** klicken
Portainer baut den Provisioner, rendert die Konfig und startet Authelia + Gateway.

### 6) Zwei Proxy-Hosts im NPM (Server A) anlegen
Beide: *Scheme* `http`, *Forward Hostname* `192.168.196.202`, *Forward Port* `8082`,
unter SSL dein Zertifikat + „Force SSL". Aktiviere **Websockets Support** (schadet nie).

| Domain                  | Forward zu                  |
|-------------------------|-----------------------------|
| `network.mfsquare.ch`   | `192.168.196.202:8082`      |
| `auth.mfsquare.ch`      | `192.168.196.202:8082`      |

Beide Domains müssen per DNS auf die öffentliche Adresse von Server A zeigen –
wie deine anderen Dienste auch.

---

## Passwort & Secrets erzeugen

**Passwort-Hash** (Standard-Passwort ist `mfsquare` – bitte ändern):
```bash
docker run --rm authelia/authelia:4.39 \
  authelia crypto hash generate argon2 --password 'DEIN-PASSWORT'
```
Ausgegebenen `$argon2id$...`-Wert als `ADMIN_PASSWORD_HASH` setzen, Stack neu deployen.

**Secrets** (je einmal ausführen):
```bash
docker run --rm authelia/authelia:4.39 authelia crypto rand --length 64
```

---

## Ändern von Einstellungen
Env-Variable in Portainer anpassen → **Update the stack**. Der Provisioner rendert neu;
die Authelia-Datenbank (`db.sqlite3`) bleibt erhalten.

- **Login-Optik:** `templates/gateway/theme/mfsquare-theme.css` im Repo ändern, committen,
  in Portainer „Pull and redeploy".
- **Logo:** `assets/logo.png` austauschen.
- **Weitere Dienste schützen:** in NPM auf `mfsquare-gateway:80` leiten und in
  `templates/gateway/conf.d/mfsquare.conf.tpl` einen weiteren `server`-Block nach dem
  Muster von `${DASHBOARD_HOST}` anlegen (mit `include .../authelia-authrequest.conf`).
- **CSS greift nicht?** In der `mfsquare.conf.tpl` die zwei auskommentierten
  `Content-Security-Policy`-Zeilen aktivieren und Stack neu deployen.

---

## Testen
1. `https://network.mfsquare.ch` → Umleitung auf `auth.mfsquare.ch` (Aurora, MFsquare-Logo).
2. Mit `admin` + Passwort anmelden → zurück aufs Dashboard.
3. Neues privates Fenster → ohne Login kein Zugriff. ✔

Der Eigen-Login des Dashboards ist in dieser Version **aus** – die Anmeldung macht Authelia,
serverseitig und nicht umgehbar. Das Passwort liegt nur als **Argon2id-Hash** vor.

## Dateien
```
docker-compose.yml     ← Stack + alle Einstellungen (Env-Variablen)
.env.example           ← Vorlage der Einstellungen (lokal)
Dockerfile             ← Provisioner-Image
entrypoint.sh          ← rendert Config in die Volumes
templates/…            ← Authelia- & nginx-Vorlagen (mit Platzhaltern)
assets/dashboard/…     ← dein Dashboard
assets/logo.png        ← MFsquare-Logo fürs Login-Portal
```
