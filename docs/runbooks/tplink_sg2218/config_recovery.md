# TP-LINK SG2218 Recovery

I discovered that this device supports setting configuration without saving it. That is, the config will not
survive reboot. Very fun. You *can* explicitly save to survive reboot. Additionally, the config can be exported.

To restore the backup:

1. Ensure that OPNsense and Tailscale are up
2. Decrypt it: `sops -d -i sysConfigBackup.sops.cfg`
3. System tools -> Restore Config
