terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.53.0"
    }
  }
}

variable "token" {
  description = "Terraform Access Token"
  type        = string
}

provider "tfe" {
  token = var.token
}

resource "tfe_organization" "slick-llc" {
  name                          = "slick-LLC"
  email                         = "ghvinerias@gmail.com"
  allow_force_delete_workspaces = true
}

# resource "tfe_oauth_client" "test" {
#   organization     = tfe_organization.slick-llc
#   api_url          = "https://api.github.com"
#   http_url         = "https://github.com"
#   oauth_token      = "oauth_token_id"
#   service_provider = "github"
# }

resource "tfe_workspace" "host" {
  name              = "host"
  organization      = tfe_organization.slick-llc.name
  project_id        = "prj-tZKesKDNLmikhk9t"
  queue_all_runs    = false
  auto_apply        = true
  working_directory = "host"
  trigger_patterns = [
    "./host/*",
  ]
  vcs_repo {
    github_app_installation_id = "ghain-6aTdtobAVBCDJ5Vd"
    identifier                 = "Ghvinerias/homelab"
    ingress_submodules         = false
  }
}

resource "tfe_workspace" "dev-tools" {
  name              = "dev-tools"
  organization      = tfe_organization.slick-llc.name
  project_id        = "prj-tZKesKDNLmikhk9t"
  queue_all_runs    = false
  auto_apply        = true
  working_directory = "dev-tools"
  trigger_patterns = [
    "./dev-tools/*",
  ]
  vcs_repo {
    github_app_installation_id = "ghain-6aTdtobAVBCDJ5Vd"
    identifier                 = "Ghvinerias/homelab"
    ingress_submodules         = false
  }
}

resource "tfe_workspace" "misho-valentine" {
  name              = "misho-valentine"
  organization      = tfe_organization.slick-llc.name
  project_id        = "prj-tZKesKDNLmikhk9t"
  queue_all_runs    = false
  auto_apply        = true
  working_directory = "terraform"
  trigger_patterns = [
    "./terraform/*",
  ]
  vcs_repo {
    github_app_installation_id = "ghain-6aTdtobAVBCDJ5Vd"
    identifier                 = "mshubitidze/valentine"
    ingress_submodules         = false
  }
}