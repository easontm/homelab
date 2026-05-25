# Cloudflare Email Routing

The API token will need the following permissions:

| Permission | Access |
|---|---|
| Zone → Email Routing Rules | Edit |
| Zone → Email Routing Addresses | Edit |
| Zone → Zone Settings | Edit |

## Notes

I was having trouble setting this up the first time, so I actually did it
through the Cloudflare console first. As a part of this process, Cloudflare
also created some extra DNS records. These are currently *NOT* captured
in this module.

It's possible that the automatic DNS rule creation would also have occurred
if I did it correctly through Terraform first, but I am not certain.
