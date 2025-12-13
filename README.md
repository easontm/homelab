# Homelab

This repo contains various IAC configs so I don't forget how I set up my
homelab.

## Setup

Recommended (sometimes required) tooling:
- Terraform
- Terragrunt
- Ansible
- sops
- age
- direnv
- kubectl

### SOPS

Because storing plaintext credentials is bad, it is recommended to use [SOPS](https://github.com/getsops/sops)
to encrypt at rest. I am using [age](https://github.com/FiloSottile/age) as my encryption method. After
installing `age` and creating a key, place the public key name in `.sops.yaml`. The default key storage location
can be found in `.env.example`.