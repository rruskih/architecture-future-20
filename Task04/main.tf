terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.95"
    }
  }
  required_version = ">= 1.0"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# VPC Network
resource "yandex_vpc_network" "main" {
  name        = "${var.project_name}-${var.env}-network"
  description = "VPC network for Future 2.0 infrastructure"
}

# NAT Gateway
resource "yandex_vpc_gateway" "nat_gateway" {
  count = var.enable_nat ? 1 : 0

  name = "${var.project_name}-${var.env}-nat-gateway"
}

resource "yandex_vpc_route_table" "nat_route_table" {
  count = var.enable_nat ? 1 : 0

  name       = "${var.project_name}-${var.env}-nat-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway[0].id
  }
}

# Public subnet (for NAT Gateway, if needed)
resource "yandex_vpc_subnet" "public_subnet" {
  count = var.enable_nat ? 1 : 0

  name           = "${var.project_name}-${var.env}-${var.nat_gateway_subnet}-subnet"
  description    = "Public subnet for NAT Gateway"
  zone           = var.subnet_cidrs[var.nat_gateway_subnet].zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_cidrs[var.nat_gateway_subnet].cidr]
}

# Private subnets (with NAT routing if enabled)
resource "yandex_vpc_subnet" "private_subnets" {
  for_each = var.enable_nat ? { for k, v in var.subnet_cidrs : k => v if k != var.nat_gateway_subnet } : var.subnet_cidrs

  name           = "${var.project_name}-${var.env}-${each.key}-subnet"
  description    = "Subnet for ${each.key} domain"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = var.enable_nat ? yandex_vpc_route_table.nat_route_table[0].id : null
}

# Security Groups
resource "yandex_vpc_security_group" "medical" {
  name        = "${var.project_name}-${var.env}-medical-sg"
  description = "Security group for Medical Domain"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = [var.subnet_cidrs["medical"].cidr, var.subnet_cidrs["shared-services"].cidr]
    description    = "PostgreSQL access from Medical and Shared Services subnets"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH access"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "fintech" {
  name        = "${var.project_name}-${var.env}-fintech-sg"
  description = "Security group for Fintech Domain"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = [var.subnet_cidrs["fintech"].cidr, var.subnet_cidrs["shared-services"].cidr]
    description    = "PostgreSQL access from Fintech and Shared Services subnets"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH access"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "ai_services" {
  name        = "${var.project_name}-${var.env}-ai-services-sg"
  description = "Security group for AI Services Domain"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 8000
    v4_cidr_blocks = [var.subnet_cidrs["medical"].cidr, var.subnet_cidrs["shared-services"].cidr]
    description    = "AI Services API access"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH access"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "analytics" {
  name        = "${var.project_name}-${var.env}-analytics-sg"
  description = "Security group for Analytics Domain"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = [var.subnet_cidrs["shared-services"].cidr]
    description    = "Analytics portal access"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH access"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "shared_services" {
  name        = "${var.project_name}-${var.env}-shared-services-sg"
  description = "Security group for Shared Services Domain"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = [var.subnet_cidrs["shared-services"].cidr, var.subnet_cidrs["medical"].cidr, var.subnet_cidrs["fintech"].cidr]
    description    = "API Gateway access"
  }

  ingress {
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = [var.subnet_cidrs["shared-services"].cidr]
    description    = "Identity Provider access"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH access"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

# Local values for subnet and security group mapping
locals {
  subnet_ids = {
    medical        = yandex_vpc_subnet.private_subnets["medical"].id
    fintech        = yandex_vpc_subnet.private_subnets["fintech"].id
    ai-services    = yandex_vpc_subnet.private_subnets["ai-services"].id
    analytics      = yandex_vpc_subnet.private_subnets["analytics"].id
    shared-services = yandex_vpc_subnet.private_subnets["shared-services"].id
  }
  
  security_group_ids = {
    medical-db     = [yandex_vpc_security_group.medical.id]
    fintech-db     = [yandex_vpc_security_group.fintech.id]
    ai-services    = [yandex_vpc_security_group.ai_services.id]
    analytics      = [yandex_vpc_security_group.analytics.id]
    shared-services = [yandex_vpc_security_group.shared_services.id]
  }
}

# Virtual Machines
resource "yandex_compute_instance" "vms" {
  for_each = var.vm_configs

  name        = "${var.project_name}-${var.env}-${each.key}"
  zone        = each.value.zone
  platform_id = each.value.platform_id

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = each.value.image_id
      size     = each.value.disk_size
      type     = each.value.disk_type
    }
  }

  network_interface {
    subnet_id          = local.subnet_ids[each.value.subnet]
    nat                = each.value.nat
    security_group_ids = local.security_group_ids[each.key]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}
