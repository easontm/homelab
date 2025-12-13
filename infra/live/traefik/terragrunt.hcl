include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  proxmox_vars = read_terragrunt_config(find_in_parent_folders("proxmox.hcl"))
  ansible_vars = read_terragrunt_config(find_in_parent_folders("ansible.hcl"))
}

terraform {
  source = "../../modules/traefik"
}

inputs = {
  proxmox_api_url          = local.proxmox_vars.locals.proxmox_api_url
  proxmox_api_token        = local.proxmox_vars.locals.api_token  
  ansible_user              = local.ansible_vars.locals.ansible_user

  target_node               = "pve4"
  vmid                      = 700
  container_repository      = "traefik"
  container_tag             = "3.6.4"
  template_storage          = "pve-shared"
  middlewares = {
    authelia = {
      forwardAuth = {
        address             = "http://192.168.1.103:9091/api/authz/forward-auth"
        trustForwardHeader  = true
        authResponseHeaders = ["Remote-User", "Remote-Groups", "Remote-Email", "Remote-Name"]
      }
    }
  }
  services = {
    nginx = {
      loadBalancer = {
        servers = [
          {
            url = "http://192.168.1.73:80"
          }
        ]
      }
    }
    authelia = {
      loadBalancer = {
        servers = [
          {
            url = "http://192.168.1.103:9091"
          }
        ]
      }
    }
  }
  routers = {
    nginx = {
      rule        = "Host(`nginx.easontm.com`)"
      entryPoints = ["websecure"]
      tls         = {}
      service     = "nginx"
      middlewares = ["authelia", "secure-headers"]
    }
    authelia = {
      rule        = "Host(`auth.easontm.com`)"
      entryPoints = ["websecure"]
      tls         = {}
      service     = "authelia"
      middlewares = []
    }
  }
}
