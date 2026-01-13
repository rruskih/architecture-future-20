variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "future-20"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type = map(object({
    zone = string
    cidr = string
  }))
  default = {
    public = {
      zone = "ru-central1-a"
      cidr = "10.0.1.0/24"
    }
    medical = {
      zone = "ru-central1-a"
      cidr = "10.0.2.0/24"
    }
    fintech = {
      zone = "ru-central1-b"
      cidr = "10.0.3.0/24"
    }
    ai-services = {
      zone = "ru-central1-a"
      cidr = "10.0.4.0/24"
    }
    analytics = {
      zone = "ru-central1-b"
      cidr = "10.0.5.0/24"
    }
    shared-services = {
      zone = "ru-central1-a"
      cidr = "10.0.6.0/24"
    }
  }
}

# VM configuration
variable "vm_configs" {
  description = "Configuration for virtual machines"
  type = map(object({
    zone            = string
    subnet          = string
    platform_id     = string
    cores           = number
    memory          = number
    core_fraction   = number
    disk_size       = number
    disk_type       = string
    image_id        = string
    nat             = bool
  }))
  default = {
    medical-db = {
      zone          = "ru-central1-a"
      subnet        = "medical"
      platform_id   = "standard-v2"
      cores         = 4
      memory        = 8
      core_fraction = 100
      disk_size     = 20
      disk_type     = "network-ssd"
      image_id      = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04
      nat           = false
    }
    fintech-db = {
      zone          = "ru-central1-b"
      subnet        = "fintech"
      platform_id   = "standard-v2"
      cores         = 4
      memory        = 8
      core_fraction = 100
      disk_size     = 20
      disk_type     = "network-ssd"
      image_id      = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04
      nat           = false
    }
    ai-services = {
      zone          = "ru-central1-a"
      subnet        = "ai-services"
      platform_id   = "standard-v2"
      cores         = 8
      memory        = 16
      core_fraction = 100
      disk_size     = 30
      disk_type     = "network-ssd"
      image_id      = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04
      nat           = false
    }
    analytics = {
      zone          = "ru-central1-b"
      subnet        = "analytics"
      platform_id   = "standard-v2"
      cores         = 8
      memory        = 32
      core_fraction = 100
      disk_size     = 50
      disk_type     = "network-ssd"
      image_id      = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04
      nat           = false
    }
    shared-services = {
      zone          = "ru-central1-a"
      subnet        = "shared-services"
      platform_id   = "standard-v2"
      cores         = 2
      memory        = 4
      core_fraction = 100
      disk_size     = 20
      disk_type     = "network-ssd"
      image_id      = "fd8kdq6d0p8sij7h5qe3" # Ubuntu 22.04
      nat           = false
    }
  }
}

# NAT Gateway configuration
variable "enable_nat" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "nat_gateway_subnet" {
  description = "Subnet for NAT Gateway"
  type        = string
  default     = "public"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
