# Kubernetes Node Setup

1. Set up a static IP
   1. Edit `/etc/netplan/50-cloud-init.yaml`
```yaml
network:
  version: 2
  ethernets:
    enp6s0:                   ## edit accordingly
      dhcp4: false
      dhcp6: false
      addresses:
        - <IP ADDR>/24       ## edit accordingly
      routes:
        - to: default
          via: <ROUTER>   ## edit accordingly
      nameservers:
        search:
          - netplanlab.local  ## optional
        addresses:
          - <DNS / ROUTER>      ## edit accordingly
```
2. Install `containerd`
   1. `sudo apt install containerd`
   2. `systemctl status containerd`
   3. `sudo mkdir /etc/containerd`
   4. `containerd config default | sudo tee /etc/containerd/config.toml`
   5. change the setting `....runc.options` -> `SystemdCgroup` to `true`
3. Ensure swap is disabled
   1. Check with `free -m`
   2. Change settings at `/etc/fstab`
4. Enable bridging
   1. `sudo sysctl -w net.ipv4.ip_forward=1`
   2. `/etc/sysctl.conf`
      1. "...enable packet forwarding for IPv4" -> uncomment the line
5. Enable `br_netfilter`
	1. `/etc/modules-load.d/k8s.conf`
	2. Literally just type `br_netfilter` and save
6. Install k8s
	1. Install gpg: 
		1. `sudo apt install gpg`
	2. Get k8s gpg key (version here doesn't matter, key is the same)
		1. `curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`
	3. Add k8s repo
		1. `echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list`
	4. Update repo
		1. `sudo apt-get update`
	5. Install
		1. `sudo apt install kubeadm kubectl kubelet`
7. (optional) Set up network storage
   1. Run the steps in [democratic-csi REAMDE](../infra/modules/democratic-csi/README.md)
   2. Run the steps in the [nfs-csi README](../infra/modules/nfs-csi/README.md)
8. Generate k8s join command from control node
   1. `sudo kubeadm token create --print-join-command`
      1. Run the output on your worker node
