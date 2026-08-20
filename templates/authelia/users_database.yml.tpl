## Wird beim Deploy vom Provisioner erzeugt. Passwort = ADMIN_PASSWORD_HASH.
## Passwort ändern: neuen Argon2-Hash erzeugen (siehe README) und als
## ADMIN_PASSWORD_HASH im Compose/Portainer setzen, dann Stack neu deployen.
users:
  ${ADMIN_USER}:
    disabled: false
    displayname: '${ADMIN_DISPLAYNAME}'
    password: '@@ADMIN_PASSWORD_HASH@@'
    email: '${ADMIN_EMAIL}'
    groups:
      - 'admins'
