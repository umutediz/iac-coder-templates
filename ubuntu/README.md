# ubuntu-workspace

Ubuntu Coder workspace with optional XFCE4 desktop via noVNC.

## How it works

The workspace image is **built in-cluster by [envbuilder](https://github.com/coder/envbuilder)**
using kaniko. Static Dockerfile variants live under `dockerfiles/` and are
selected from the Ubuntu version and desktop parameters.

Startup scripts and noVNC support files live under `scripts/` and `files/`, then
Terraform injects them with `file()` and `templatefile()` calls.

Envbuilder uses the in-cluster registry configured by `cache_repo`. The
selected Dockerfile and helper scripts are injected into the workspace pod as a
ConfigMap-backed build context, so the build does not require access to this Git
repository at runtime. The pod runs envbuilder and pushes the resulting image
back to the cache. Per-pod local build cache lives on the ephemeral workspace
volume so simultaneous workspaces can mount the same shared home safely.

APT installs opportunistically use `http://cache-server.lab.ediz.dev:3142`.
If the apt cache is down or slow, package installation retries without the proxy
so workspace builds do not depend on the cache.

## Pushing the template

```bash
cd clusters/prod/apps/coder/templates/ubuntu
coder templates push ubuntu --directory . --yes
```

To update:

```bash
coder templates push ubuntu --directory . --yes --message "describe change"
```

Pushing a new version with a changed Dockerfile invalidates cached layers; the next
workspace start will rebuild from the changed layer onward.

## Persistent home directories

Each user gets one PVC `coder-<user-id>-home` in `coder-workspaces`, backed by
`nfs-fast-annotated` (TrueNAS NFS, NVMe, `reclaimPolicy: Retain`). The PVC uses
`ReadWriteMany` so the same home can be mounted by multiple workspaces at once.

The NFS CSI subdir path is `coder-workspaces/coder-<user-id>-home`. Because the
reclaim policy is Retain, the data on TrueNAS survives PV deletion if the backing
directory is preserved.
