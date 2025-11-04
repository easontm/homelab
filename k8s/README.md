## Storage

Without networked storage, I am using the [local path provisioner](https://github.com/rancher/local-path-provisioner?tab=readme-ov-file) from Rancher.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
```