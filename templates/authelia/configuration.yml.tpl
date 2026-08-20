## Wird beim Deploy vom Provisioner aus Umgebungsvariablen erzeugt.
## Nicht direkt bearbeiten – Einstellungen macht man im docker-compose.yml
## bzw. in Portainers "Environment variables".

theme: dark

server:
  address: 'tcp://0.0.0.0:9091'
  asset_path: '/config/assets/'
  endpoints:
    authz:
      auth-request:
        implementation: 'AuthRequest'

log:
  level: '${LOG_LEVEL}'

authentication_backend:
  file:
    path: '/config/users_database.yml'
    password:
      algorithm: 'argon2'

access_control:
  default_policy: 'one_factor'

session:
  secret: '${SESSION_SECRET}'
  cookies:
    - domain: '${DOMAIN}'
      authelia_url: 'https://${AUTH_HOST}'
      default_redirection_url: 'https://${DASHBOARD_HOST}'
      name: 'authelia_session'
      expiration: '${SESSION_EXPIRATION}'
      inactivity: '${SESSION_INACTIVITY}'

regulation:
  max_retries: 3
  find_time: '2 minutes'
  ban_time: '5 minutes'

identity_validation:
  reset_password:
    jwt_secret: '${JWT_SECRET}'

storage:
  encryption_key: '${STORAGE_ENCRYPTION_KEY}'
  local:
    path: '/config/db.sqlite3'

notifier:
  filesystem:
    filename: '/config/notification.txt'
