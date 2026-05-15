---
display_name: Kubernetes (Devcontainer)
description: Provision envbuilder pods as Coder workspaces
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [container, kubernetes, devcontainer]
---

# Remote Development on Kubernetes Pods (with Devcontainers)

Provision Devcontainers as [Coder workspaces](https://coder.com/docs/workspaces) on Kubernetes with this example template.

## Prerequisites

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster.

**Container Image**: This template uses the [envbuilder image](https://github.com/coder/envbuilder) to build a Devcontainer from a `devcontainer.json`.

**(Optional) Cache Registry**: Envbuilder can utilize a Docker registry as a cache to speed up workspace builds. The [envbuilder Terraform provider](https://github.com/coder/terraform-provider-envbuilder) will check the contents of the cache to determine if a prebuilt image exists. In the case of some missing layers in the registry (partial cache miss), Envbuilder can still utilize some of the build cache from the registry.

### Authentication

This template authenticates to Kubernetes using the in-cluster Coder ServiceAccount.

## Architecture

Coder supports devcontainers with [envbuilder](https://github.com/coder/envbuilder), an open source project. Read more about this in [Coder's documentation](https://coder.com/docs/templates/dev-containers).

This template provisions the following resources:

- Kubernetes deployment (ephemeral)
- Kubernetes persistent volume claim (persistent on `/workspaces`)
- Envbuilder cached image (optional, persistent).

This template will fetch a Git repo containing a `devcontainer.json` specified by the `repo` parameter, and builds it
with [`envbuilder`](https://github.com/coder/envbuilder).
The Git repository is cloned inside the `/workspaces` volume if not present.
Any local changes to the Devcontainer files inside the volume will be applied when you restart the workspace.
As you might suspect, any tools or files outside of `/workspaces` or not added as part of the Devcontainer specification are not persisted.
Edit the `devcontainer.json` instead!

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Caching

This repo deploys an in-cluster Docker registry cache at
`coder-image-cache.coder.svc.cluster.local:5000` backed by NFS storage. The
template uses `coder-image-cache.coder.svc.cluster.local:5000/coder-devcontainer-cache`
by default.

You can override `cache_repo` when creating the template to use a different
registry cache.

See the [Envbuilder Terraform Provider Examples](https://github.com/coder/terraform-provider-envbuilder/blob/main/examples/resources/envbuilder_cached_image/envbuilder_cached_image_resource.tf/) for a more complete example of how the provider works.

> [!NOTE]
> We recommend using a registry cache with authentication enabled.
> To allow Envbuilder to authenticate with the registry cache, specify the variable `cache_repo_dockerconfig_secret`
> with the name of a Kubernetes secret in the same namespace as Coder. The secret must contain the key `.dockerconfigjson`.
