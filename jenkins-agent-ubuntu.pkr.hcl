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
  default = "1.1.0"
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
  default = "0001-com-ubuntu-server-focal"
}

variable "image_publisher" {
  type = string
  default = "Canonical"
}

variable "image_sku" {
  type = string
  default = "20_04-lts"
}

variable "image_name" {
  type = string
  default = "jenkins-ubuntu"
}

variable "os_type" {
  type = string
  default = "Linux"
}

variable "vm_size" {
  type = string
  default = "Standard_A2_v2"
}

source "azure-arm" "no-publish" {
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
  managed_image_name                = "${var.image_name}-${formatdate("YYYYMMDDhhmmss",timestamp())}"
  managed_image_resource_group_name = var.resource_group_name
  os_type                           = var.os_type
  ssh_pty                           = "true"
  ssh_username                      = var.ssh_user
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  vm_size                           = var.vm_size
}

source "azure-arm" "build-and-publish" {
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
  managed_image_name                = "${var.image_name}-${formatdate("YYYYMMDDhhmmss",timestamp())}"
  managed_image_resource_group_name = var.resource_group_name
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
     image_name          = "jenkins-ubuntu"
     image_version       = var.azure_image_version
     replication_regions = ["UK South"]
   }
}

build {
  sources = ["source.azure-arm.no-publish","source.azure-arm.build-and-publish"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "provision-jenkins-ubuntu-agent.sh"
    environment_vars = ["JENKINS_SSH_KEY=${var.jenkins_ssh_key}"]
  }

}
