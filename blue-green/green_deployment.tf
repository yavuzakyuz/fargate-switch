##############################################################################
### Green Deployment
##############################################################################


# Based on the local.deploy_green, we can conditionally create the blue service and its dependencies.

resource "aws_service_discovery_http_namespace" "this_green" {
  count       = local.deploy_green ? 1 : 0
  name        = "${local.name}-green"
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
}

module "ecs_service_green" {
  count  = local.deploy_green ? 1 : 0
  source = "../modules/service"

  name        = "${local.name}-green"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 4096

  container_definitions = {
    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${local.green_image}"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      readonly_root_filesystem = false

      enable_cloudwatch_logging = false
      memory_reservation        = 100
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this_green[0].arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(
        [for arn in module.alb.target_group_arns : arn if length(regexall("${local.name}-${local.container_name}-green", arn)) > 0],
        0
      )
      container_name = local.container_name
      container_port = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb_sg.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}


