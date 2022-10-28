terraform {
  required_version = "1.3.1"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {}
}

provider "digitalocean" {
  token             = var.digitalocean.token
  spaces_access_id  = var.digitalocean.spaces_access_id
  spaces_secret_key = var.digitalocean.spaces_secret_key
}

locals {
  development = "${var.project_name}-${var.environment.development}"
  staging = "${var.project_name}-${var.environment.staging}"
}

resource "digitalocean_project" "project" {
  name        = var.project_name
  is_default  = true
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "${var.project_name}_ssh_key"
  public_key = file("${path.module}/.ssh/id_rsa.pub")
}

module "development" {
  source                  = "./modules/development"

  droplet_name            = "${local.development}-server"
  droplet_image           = var.droplet.image
  droplet_region          = var.common.region
  droplet_size            = var.droplet.size
  droplet_ssh_keys        = [digitalocean_ssh_key.ssh_key.fingerprint]
  droplet_private_ssh_key = file("${path.module}/.ssh/id_rsa")
  droplet_scripts         = ["./scripts/install_docker.sh"]

  database_label          = "${local.development}-database"
  database_engine         = var.database.engine
  database_version        = var.database.version
  database_size           = var.database.size
  database_region         = var.common.region
  database_node_count     = var.database.node_count
  database_name           = var.database.name
  database_user           = var.database.user

  bucket_name             = "${local.development}-bucket-new"
  bucket_region           = var.common.region

  project                 = digitalocean_project.project.id
}

module "staging" {
  source                  = "./modules/staging"

  droplet_name            = "${local.staging}-server"
  droplet_image           = var.droplet.image
  droplet_region          = var.common.region
  droplet_size            = var.droplet.size
  droplet_ssh_keys        = [digitalocean_ssh_key.ssh_key.fingerprint]
  droplet_private_ssh_key = file("${path.module}/.ssh/id_rsa")
  droplet_scripts         = ["./scripts/install_docker.sh"]

  database_label          = "${local.staging}-database"
  database_engine         = var.database.engine
  database_version        = var.database.version
  database_size           = var.database.size
  database_region         = var.common.region
  database_node_count     = var.database.node_count
  database_name           = var.database.name
  database_user           = var.database.user

  bucket_name             = "${local.staging}-bucket-new"
  bucket_region           = var.common.region

  project                 = digitalocean_project.project.id
}
