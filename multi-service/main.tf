provider "aws" {
  region = local.region
  access_key = var.my_access_key
  secret_key = var.my_secret_key   
}



data "aws_availability_zones" "available" {}

# Based on the local.deploy_blue, we can conditionally create the blue service and its dependencies.
output "ecs_services_map" {
  value = local.ecs_services_map
}

locals {
  region   = "us-west-2"
  name     = "example"
  domain   = "foobar.com"
  image    = "public.ecr.aws/lts/apache2"
  vpc_cidr = "10.0.0.0/16"
  ecs_services_map = {
    for key, service in local.ecs_services : key => {
      index   = index(keys(local.ecs_services), key),
      service = service
    }
  }
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  target_groups = [
    for key, service in local.ecs_services : {
      target_group_index = local.ecs_services_map[key].index
      name               = "${local.name}-${service.container_name}-${key}"
      backend_protocol   = "HTTP"
      backend_port       = tonumber(service.container_port)
      target_type        = "ip"
    }
  ]

  http_tcp_listener_rules = [for key, service in local.ecs_services : {
    http_tcp_listener_index = 0
    actions = [{
      type               = "forward"
      target_group_index = local.ecs_services_map[key].index
    }]

    conditions = [{
      host_headers = [service.domain]
    }]
  }]
  tags = {
    Name = local.name
  }
}

output "target_groups" {
  value = local.target_groups
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "../modules/cluster"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

