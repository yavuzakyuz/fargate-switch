provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

# Based on the local.deploy_blue, we can conditionally create the blue service and its dependencies.

locals {
  deploy_green        = true
  deploy_blue         = true
  active_deployment   = "green"
  blue_image_version  = "2.4-22.04_beta"
  green_image_version = "latest"
  blue_image          = "public.ecr.aws/lts/apache2:${local.blue_image_version}"
  green_image         = "public.ecr.aws/nginx/nginx:${local.green_image_version}"
  region              = "us-west-2"
  name                = "ex-${basename(path.cwd)}"
  vpc_cidr            = "10.0.0.0/16"
  azs                 = slice(data.aws_availability_zones.available.names, 0, 3)
  container_name      = "ecsdemo"
  container_port      = 80

  tags = {
    Name = local.name
  }
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "../modules/cluster"

  cluster_name = local.name

  # Capacity provider
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

