# Cloudflare

This module sets up Cloudflare DNS records and a tunnel to allow ingress.
It also includes basic Zero-Trust access controls (email OTP only). This
is not intended as the main form of security (that's what Authelia
middleware is for), but this extra layer means it's much harder for interlopers
to even try to poke the system (they can't even get to Authelia).

This module does NOT deploy a container for the Cloudflare Daemon,
but it does require that you have done so. There is some commented out
code to do it, but for some reason when I ran the OCI image I would have
network problems. I did not have the same problems when installing
Cloudflared on a Debian LXC so here we are.

## Prerequisites

1. You must own a domain
2. This domain must be managed by Cloudflare
3. Your account has a Cloudflare One team

## Installation

1. Set your Cloudflare vars (see .env.example)
2. Install the module
3. Set up container
   1. Create a Debian LXC
   2. Go get the install and service create commands from the Cloudflare dashboard at: `Networks -> Connectors -> (click tunnel name) -> Edit -> Debian`

If you have trouble connecting, you can actually view the tunnel daemon's
logs in the Cloudflare UI instead of trying to get them from the container.
