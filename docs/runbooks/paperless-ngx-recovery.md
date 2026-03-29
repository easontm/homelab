# paperless-ngx Recovery

Paperless is backed up daily by a k8s cronjob. It runs the document-exporter,
and the contents of that PVC are sent to Backblaze B2 via a TrueNAS CloudSync
job.

Restoring is accomplished with the [Document Importer](https://docs.paperless-ngx.com/administration/#importer).

If you're recovering from some disaster that somehow has the backup PVC still
alive, then you can run the [debug pod](../../infra/live/k8s/paperless-ngx/debug-pod.yaml)
and copy the data over to the main `webserver-export` volume:

```bash
cp \
  /usr/src/paperless/export-backup/export-YYYY-MM-DD.zip \
  /usr/src/paperless/export/export-YYYY-MM-DD.zip
```

If you had to recover the export from Backblaze, then copy it to the pod:

```bash
kubectl cp ./export-YYYY-MM-DD.zip /usr/src/paperless/export/export-YYYY-MM-DD.zip
```

After you've done one of the above, then run the `document-importer` from the main webserver pod:

```bash
kubectl exec -it webserver-******** -- /bin/bash
document_importer /usr/src/paperless/export/export-YYYY-MM-DD.zip
```
