# paperless-ngx

This is a collection of k8s manifests for running paperless-ngx. It was initially based off
of the docker-compose file provided on the paperless-ngx site.

## Requirements

1. `kubectl`
2. `direnv`

## Installation

1. Create a `.env` file by copying `.env.example`
2. Populate with credentials
3. `kubectl apply -k .`

## Notes

- This repo assumes you have a k8s namespace called `paperless-ngx` (you can change this in
  the `.kube/config` file in this repo)