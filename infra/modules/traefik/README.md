# Traefik

This is currently implemented by using Proxmox's OCI -> LXC converter on
the image `traefik`.

## Usage

Middlewares, services, and routers are all configured with schema-less objects.
You can use whatever attributes you need, as long as they all have the same key
list (that is, you may need to set the key as null/empty for objects which don't 
need to use a specific feature).