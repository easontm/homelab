# Cloudflare

This module sets up Cloudflare DNS records and a tunnel to allow ingress.

This module does NOT deploy a container for the Cloudflare Daemon,
but it does require that you have done so. There is some commented out
code to do it, but for some reason when I ran the OCI image I would have
network problems. I did not have the same problems when installing
Cloudflared on a Debian LXC so here we are.

# Installation

1. Get your token
2. Install the module
3. Set up container
   1. Create a Debian LXC
   2. Go get the install and service create commands from the Cloudflare dashboard at: `Networks -> Connectors -> (click tunnel name) -> Edit -> Debian`

If you have trouble connecting, you can actually view the tunnel daemon's
logs in the Cloudflare UI instead of trying to get them from the container.
