# TP-LINK SG2218 Recovery

I discovered that this device supports setting configuration without saving it. That is, the config will not
survive reboot. Very fun. You *can* explicitly save to survive reboot. Additionally, the config can be exported.

To restore the backup:

1. Ensure that OPNsense and Tailscale are up
2. Decrypt it: `sops -d -i sysConfigBackup.sops.cfg`
3. System tools -> Restore Config

Yes, putting this here is not... the most secure thing. The user password is in this file, although encrypted.
However, accessing the switch requires physical access or access to my Tailnet. If my Tailnet is compromised
I'm already in a bad spot. If someone manages to decrypt this file at the same time they probably deserve it.
