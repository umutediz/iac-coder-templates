terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    envbuilder = {
      source  = "coder/envbuilder"
      version = "~> 1.0"
    }
  }
}

provider "coder" {}

# Uses in-cluster kubeconfig when running inside the Coder pod.
provider "kubernetes" {}
provider "envbuilder" {}

# ─── Admin variables ─────────────────────────────────────────────────────────

variable "namespace" {
  description = "Kubernetes namespace where workspace pods and PVCs are created"
  type        = string
  default     = "coder-workspaces"
}

variable "storage_class" {
  description = "StorageClass for persistent home directories"
  type        = string
  default     = "nfs-fast-annotated"
}

variable "cache_repo" {
  description = "Container registry repository used as an envbuilder image cache"
  type        = string
  default     = "coder-image-cache.coder.svc.cluster.local:5000/coder-ubuntu-cache"
}

variable "insecure_cache_repo" {
  description = "Enable this option if your cache registry does not serve HTTPS"
  type        = bool
  default     = true
}

variable "template_repo_url" {
  description = "Public Git repository containing the Ubuntu envbuilder Dockerfiles"
  type        = string
  default     = "https://github.com/umutediz/iac-coder-templates.git"
}

variable "template_repo_ref" {
  description = "Git ref for template_repo_url. Keep this aligned with the pushed template version."
  type        = string
  default     = "main"
}

# ─── User parameters ─────────────────────────────────────────────────────────

data "coder_parameter" "os_version" {
  name         = "os_version"
  display_name = "Ubuntu Version"
  description  = "Ubuntu LTS release. Cannot be changed after creation."
  type         = "string"
  default      = "24.04"
  mutable      = false
  icon         = "/icon/ubuntu.svg"
  order        = 1

  option {
    name  = "Ubuntu 24.04 LTS (Noble)"
    value = "24.04"
  }

  option {
    name  = "Ubuntu 22.04 LTS (Jammy)"
    value = "22.04"
  }

  option {
    name  = "Ubuntu 20.04 LTS (Focal)"
    value = "20.04"
  }
}

data "coder_parameter" "gui_mode" {
  name         = "gui_mode"
  display_name = "Desktop Environment"
  description  = "Choose the browser desktop environment exposed through noVNC. Cannot be changed after creation."
  type         = "string"
  default      = "none"
  mutable      = false
  icon         = "/icon/desktop.svg"
  order        = 2

  option {
    name  = "No GUI"
    value = "none"
  }

  option {
    name  = "XFCE"
    value = "xfce"
  }
}

data "coder_parameter" "home_mode" {
  name         = "home_mode"
  display_name = "Home Directory"
  description  = "Choose whether to reuse your shared home or use ephemeral storage."
  type         = "string"
  default      = "shared"
  mutable      = false
  icon         = "/icon/folder.svg"
  order        = 3

  option {
    name  = "Shared user home"
    value = "shared"
  }

  option {
    name  = "Ephemeral home"
    value = "ephemeral"
  }
}

# ─── Workspace context ───────────────────────────────────────────────────────

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  gui_mode        = data.coder_parameter.gui_mode.value
  xfce_enabled    = local.gui_mode == "xfce"
  desktop_enabled = local.gui_mode != "none"

  username         = lower(replace(data.coder_workspace_owner.me.name, "/[^a-zA-Z0-9]/", "-"))
  workspace_slug   = lower(replace(data.coder_workspace.me.name, "/[^a-zA-Z0-9]/", "-"))
  workspace_suffix = substr(sha1(data.coder_workspace.me.id), 0, 8)

  home_mode      = data.coder_parameter.home_mode.value
  ephemeral_home = local.home_mode == "ephemeral"

  shared_home_name = "coder-${data.coder_workspace_owner.me.id}-home"
  home_pvc_name    = local.shared_home_name
  home_volume_size = "4Gi"

  builder_image        = "ghcr.io/coder/envbuilder:1.3.0"
  dockerfile_variant   = local.desktop_enabled ? "xfce" : "cli"
  dockerfile_path      = "ubuntu/dockerfiles/ubuntu-${data.coder_parameter.os_version.value}-${local.dockerfile_variant}.Dockerfile"
  build_context_path   = "ubuntu"
  template_git_url     = var.template_repo_ref == "" ? var.template_repo_url : "${var.template_repo_url}#refs/heads/${var.template_repo_ref}"
  workspace_folder     = "/workspaces/iac-coder-templates"
  layer_cache_dir      = "${local.workspace_folder}/.cache/envbuilder/layers"
  base_image_cache_dir = "${local.workspace_folder}/.cache/envbuilder/base"

  envbuilder_env = {
    CODER_AGENT_TOKEN                 = coder_agent.main.token
    CODER_AGENT_URL                   = replace(data.coder_workspace.me.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
    ENVBUILDER_INIT_SCRIPT            = replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
    ENVBUILDER_GIT_URL                = local.template_git_url
    ENVBUILDER_DOCKERFILE_PATH        = local.dockerfile_path
    ENVBUILDER_BUILD_CONTEXT_PATH     = local.build_context_path
    ENVBUILDER_WORKSPACE_FOLDER       = local.workspace_folder
    ENVBUILDER_LAYER_CACHE_DIR        = local.layer_cache_dir
    ENVBUILDER_BASE_IMAGE_CACHE_DIR   = local.base_image_cache_dir
    ENVBUILDER_CACHE_REPO             = var.cache_repo
    ENVBUILDER_PUSH_IMAGE             = var.cache_repo != "" ? "true" : ""
    ENVBUILDER_INSECURE               = tostring(var.insecure_cache_repo)
    ENVBUILDER_REMOTE_REPO_BUILD_MODE = "true"
    HOME                              = "/home/coder"
  }

  desktop_settings      = local.xfce_enabled ? file("${path.module}/scripts/xfce-settings.sh") : ""
  desktop_pre_start     = ""
  desktop_start_command = local.xfce_enabled ? "exec dbus-launch --exit-with-session startxfce4" : ""

  _desktop_startup = templatefile("${path.module}/scripts/desktop-startup.sh.tftpl", {
    desktop_pre_start = local.desktop_pre_start
    desktop_settings  = local.desktop_settings
    novnc_index_html  = file("${path.module}/files/novnc-index.html")
    novnc_nginx_conf  = file("${path.module}/files/novnc-nginx.conf")
    vnc_config        = file("${path.module}/files/vnc-config")
    vnc_xstartup      = templatefile("${path.module}/scripts/vnc-xstartup.sh.tftpl", { desktop_start_command = local.desktop_start_command })
  })

  _cli_startup = file("${path.module}/scripts/cli-startup.sh")

  startup_script = local.desktop_enabled ? local._desktop_startup : local._cli_startup
}

resource "envbuilder_cached_image" "ubuntu" {
  count              = var.cache_repo == "" ? 0 : data.coder_workspace.me.start_count
  builder_image      = local.builder_image
  git_url            = local.template_git_url
  cache_repo         = var.cache_repo
  dockerfile_path    = local.dockerfile_path
  build_context_path = local.build_context_path
  workspace_folder   = local.workspace_folder
  extra_env          = local.envbuilder_env
  insecure           = var.insecure_cache_repo
}

# ─── Coder agent ─────────────────────────────────────────────────────────────

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  env = {
    HOME                = "/home/coder"
    USER                = "coder"
    SHELL               = "/bin/bash"
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }

  startup_script = local.startup_script

  display_apps {
    vscode                 = true
    vscode_insiders        = false
    web_terminal           = true
    ssh_helper             = true
    port_forwarding_helper = true
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "2_home_disk"
    script       = "coder stat disk --path /home/coder"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "3_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "4_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "5_load_host"
    script       = <<-EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval     = 60
    timeout      = 1
  }
}

# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/code-server/coder"
  version = "~> 1.0"

  agent_id = coder_agent.main.id
  order    = 1
}

resource "coder_app" "novnc" {
  count = local.desktop_enabled ? 1 : 0

  agent_id     = coder_agent.main.id
  slug         = "desktop"
  display_name = "Desktop"
  icon         = "/icon/novnc.svg"
  url          = "http://localhost:6081/"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:6081/"
    interval  = 5
    threshold = 10
  }
}

# ─── Shared home bootstrap ───────────────────────────────────────────────────
#
# Terraform should not own the shared per-user PVC, otherwise deleting one
# workspace could delete a home that other workspaces still mount.

resource "kubernetes_job_v1" "shared_home" {
  count = local.home_mode == "shared" ? 1 : 0

  metadata {
    name      = "ensure-${local.shared_home_name}-${local.workspace_suffix}"
    namespace = "coder"

    labels = {
      "app.kubernetes.io/name" = "coder-shared-home-bootstrap"
      "coder.com/user-id"      = data.coder_workspace_owner.me.id
      "coder.com/user-name"    = local.username
    }
  }

  wait_for_completion = true

  spec {
    ttl_seconds_after_finished = 300
    backoff_limit              = 3

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "coder-shared-home-bootstrap"
          "coder.com/user-id"      = data.coder_workspace_owner.me.id
          "coder.com/user-name"    = local.username
        }
      }

      spec {
        service_account_name = "coder"
        restart_policy       = "OnFailure"

        container {
          name  = "kubectl"
          image = "bitnami/kubectl@sha256:13dc27afebffa1065bf7602d72a2d2e77019647fc11e591cead5e68304c8e914"

          command = ["/bin/sh", "-c"]

          args = [templatefile("${path.module}/scripts/ensure-home-pvc.sh.tftpl", {
            namespace     = var.namespace
            pvc_name      = local.shared_home_name
            storage_class = var.storage_class
            storage_size  = local.home_volume_size
            user_id       = data.coder_workspace_owner.me.id
            user_name     = local.username
          })]
        }
      }
    }
  }
}

# ─── Workspace deployment ────────────────────────────────────────────────────

resource "kubernetes_deployment_v1" "workspace" {
  count = data.coder_workspace.me.start_count

  depends_on = [
    kubernetes_job_v1.shared_home,
  ]

  wait_for_rollout = false

  metadata {
    name      = "coder-${local.username}-${local.workspace_slug}"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"    = "coder-workspace"
      "app.kubernetes.io/part-of" = "coder"
      "coder.com/workspace-id"    = data.coder_workspace.me.id
      "coder.com/workspace-name"  = data.coder_workspace.me.name
      "coder.com/user-id"         = data.coder_workspace_owner.me.id
      "coder.com/user-name"       = local.username
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "coder-workspace"
        "coder.com/workspace-id" = data.coder_workspace.me.id
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"   = "coder-workspace"
          "coder.com/workspace-id"   = data.coder_workspace.me.id
          "coder.com/workspace-name" = data.coder_workspace.me.name
          "coder.com/user-id"        = data.coder_workspace_owner.me.id
          "coder.com/user-name"      = local.username
        }
      }

      spec {
        automount_service_account_token = false

        init_container {
          name  = "init-home"
          image = "busybox:1.37.0"

          command = [
            "sh",
            "-c",
            file("${path.module}/scripts/init-home.sh"),
          ]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            name       = "home"
            mount_path = "/home/coder"
          }
        }

        container {
          name              = "workspace"
          image             = var.cache_repo == "" ? local.builder_image : envbuilder_cached_image.ubuntu[0].image
          image_pull_policy = "Always"

          security_context {
            run_as_user = 0
          }

          dynamic "env" {
            for_each = nonsensitive(var.cache_repo == "" ? local.envbuilder_env : envbuilder_cached_image.ubuntu[0].env_map)
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "home"
            mount_path = "/home/coder"
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/workspaces"
          }
        }

        volume {
          name = "home"

          dynamic "persistent_volume_claim" {
            for_each = local.ephemeral_home ? [] : [1]

            content {
              claim_name = local.home_pvc_name
            }
          }

          dynamic "empty_dir" {
            for_each = local.ephemeral_home ? [1] : []

            content {}
          }
        }

        volume {
          name = "workspace"

          empty_dir {}
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

# ─── Workspace metadata ───────────────────────────────────────────────────────

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = coder_agent.main.id

  item {
    key   = "ubuntu version"
    value = data.coder_parameter.os_version.value
  }

  item {
    key   = "desktop"
    value = local.gui_mode
  }

  item {
    key   = "home mode"
    value = local.home_mode
  }

  item {
    key   = "cache repo"
    value = var.cache_repo != "" ? var.cache_repo : "not enabled"
  }
}
