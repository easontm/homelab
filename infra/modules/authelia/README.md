# Authelia

This module creates an LXC container from the Authelia OCI image and provisions it with
a file-based user config.

Right now, fetching and returning the IP of the Authelia container is not supported. IP
is an attribute of the resource, but since I leave the container in an unstarted state
so that I may add its config, the resource doesn't have this attribute. I *did* try to
have the container start on its own so the attribute would populate and then shut it down
via playbook, but the container errors without having a config ready.

## Managing Inputs

Because configuring this module involves several sensitive fields,
you may not want to embed those values in your `terragrunt.hcl` file.
I've provided a template, `authelia_vars_template.yaml` which you can
populate and load in your Terragrunt locals. If you would like to track
these values in source control, it is recommended to use SOPS (see root
README).

You can then encrypt this information with

```bash
sops -e authelia_vars_template.yaml > authelia_vars.sops.yaml
```
and extract the data at runtime with

```terraform
users = yamldecode(sops_decrypt_file("./authelia_vars.sops.yaml"))
```

The yaml file has to be a dict (not a list) at the root, so pass the values to the module like so:

```terragrunt
authelia_users = local.authelia_vars.users
```

### User Passwords

To generate passwords for the static file user config, either install
the Authelia binary or just run the docker image like so:

```bash
docker run --entrypoint=/bin/sh -it authelia/authelia:latest
authelia crypto hash generate argon2 --password 'mypassword`
```

## Further configuration

Configuration is applied by rendering the Jinja template `configuration.j2`.
Current config is extremely basic, and if you need to make changes you
should further edit the template.

## Other Notes

This module also contains `fetch_template_playbook.yaml` and a section in
`main.tf` for fetching the OCI image using commands run directly on the
Proxmox host. These aren't needed currently, as the OCI image resource 
seems to be working fine. However, I'm not 100% confident yet so these
shall remain as an archive.