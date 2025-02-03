variable "client_id" {
  type    = string
  default = ""
}

variable "client_secret" {
  type    = string
  default = ""
}

variable "azure_image_version" {
  type    = string
  default = "0.0.1"
  description = "This is the version of the image definition in the Azure Compute Gallery. Ignore the default value set here as this will be computed in the pipeline to ensure it is automatically incremented"
}

variable "azure_location" {
  type    = string
  default = "uksouth"
}

variable "azure_object_id" {
  type    = string
  default = ""
}

variable "resource_group_name" {
  type    = string
  default = "hmcts-image-gallery-rg"
}

variable "azure_storage_account" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type    = string
  default = ""
}

variable "ssh_password" {
  type    = string
  default = ""
}

variable "jenkins_ssh_key" {
  type    = string
  default = ""
}

variable "image_offer" {
  type = string
  default = "ubuntu-24_04-lts"
}

variable "image_publisher" {
  type = string
  default = "Canonical"
}

variable "image_sku" {
  type = string
  default = "server"
}

variable "image_name" {
  type = string
  default = "jenkins-ubuntu-v2"
}

variable "os_type" {
  type = string
  default = "Linux"
}

variable "vm_size" {
  type = string
  default = "Standard_D4ds_v5"
}

source "azure-arm" "pr-build-and-publish" {
  azure_tags = {
    imagetype = var.image_name
    timestamp = formatdate("YYYYMMDDhhmmss",timestamp())
  }
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  image_publisher                   = var.image_publisher
  image_offer                       = var.image_offer
  image_sku                         = var.image_sku
  location                          = var.azure_location
  os_type                           = var.os_type
  ssh_pty                           = "true"
  ssh_username                      = var.ssh_user
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = var.vm_size

  shared_image_gallery_destination {
     subscription        = var.subscription_id
     resource_group      = var.resource_group_name
     gallery_name        = "hmcts"
     image_name          = var.image_name
     image_version       = var.azure_image_version
     replication_regions = ["UK South"]
   }
  
  shared_gallery_image_version_exclude_from_latest = true
}

source "azure-arm" "master-build-and-publish" {
  azure_tags = {
    imagetype = var.image_name
    timestamp = formatdate("YYYYMMDDhhmmss",timestamp())
  }
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  image_publisher                   = var.image_publisher
  image_offer                       = var.image_offer
  image_sku                         = var.image_sku
  location                          = var.azure_location
  os_type                           = var.os_type
  ssh_pty                           = "true"
  ssh_username                      = var.ssh_user
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = var.vm_size

  shared_image_gallery_destination {
    subscription        = var.subscription_id
    resource_group      = var.resource_group_name
    gallery_name        = "hmcts"
    image_name          = var.image_name
    image_version       = var.azure_image_version
    replication_regions = ["UK South"]
  }
}

build {
  sources = ["source.azure-arm.pr-build-and-publish","source.azure-arm.master-build-and-publish"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "provision-jenkins-ubuntu-agent.sh"
    environment_vars = ["JENKINS_SSH_KEY=${var.jenkins_ssh_key}"]
    max_retries = 5
  }

}
