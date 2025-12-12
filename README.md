# Homelab Reverse Proxy + Auth (Traefik + Authelia)

This config secures a test Nginx service behind Traefik with Authelia Forward-Auth.

## Files mounted into containers

- Traefik
  - `/etc/traefik/traefik.yaml` <- `traefik/traefik.yaml`
  - `/etc/traefik/conf` <- `traefik/conf/`
- Authelia
  - `/config/configuration.yaml` <- `authelia/configuration.yaml`
  - `/config/users_database.yml` <- `authelia/users_database.yml`

## Test target

- Nginx dummy upstream at http://192.168.1.73:80
- Access via Traefik: https://192.168.1.72/nginx

## Notes

- Update `<AUTHELIA_URL>` in `traefik/conf/nginx.yaml` and `authelia/configuration.yaml` to your Authelia URL (https scheme recommended).
- Generate a real Argon2id password hash and replace the placeholder in `authelia/users_database.yml`.
- The Traefik dashboard is enabled but not exposed via an external router by default (insecure=false). Expose it only via a protected router if needed.
- TLS certificates: enable Let’s Encrypt in `traefik/traefik.yaml` if you have public DNS; otherwise use internal certificates.

## Minimal docker-compose snippets (optional)

These are examples; adapt to LXC container mounts in Proxmox.

```yaml
# traefik-docker-compose.yaml (optional reference)
services:
  traefik:
    image: traefik:v3.1
    command:
      - --providers.file.directory=/etc/traefik/conf
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./traefik/traefik.yaml:/etc/traefik/traefik.yaml:ro
      - ./traefik/conf:/etc/traefik/conf:ro

# authelia-docker-compose.yaml (optional reference)
services:
  authelia:
    image: authelia/authelia:latest
    volumes:
      - ./authelia/configuration.yaml:/config/configuration.yaml:ro
      - ./authelia/users_database.yml:/config/users_database.yml:ro
    ports:
      - "9091:9091"
```

## Verify

1. Start Traefik and Authelia containers.
2. Browse to https://192.168.1.72/nginx
3. You should be redirected to Authelia, login as `demo` (after replacing the password hash and enrolling 2FA), then be forwarded to the Nginx test page.

## Setup

### SOPS

ecause storing plaintext credentials is bad, it is recommended to use [SOPS](https://github.com/getsops/sops)
to encrypt at rest. I am using [age](https://github.com/FiloSottile/age) as my encryption method. After
installing `age` and creating a key, place the public key name in `.sops.yaml`. The default key storage location
can be found in `.env.example`.