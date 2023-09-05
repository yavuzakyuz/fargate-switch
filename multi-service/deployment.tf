###############################################################################
##### Blue Deployment
###############################################################################

resource "aws_service_discovery_http_namespace" "this" {
  for_each    = { for k, v in local.ecs_services_map : k => v.service }
  name        = "${local.name}-${each.key}"
  description = "CloudMap namespace for ${local.name}"
  tags        = local.tags
}



module "ecs_service" {
  for_each = { for k, v in local.ecs_services_map : k => v }
  source   = "../modules/service"

  name        = "${local.name}-${each.key}"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024
  memory = 4096

  container_definitions = {
    (each.value.service.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${local.image}:${each.value.service.image_tag}"
      port_mappings = [
        {
          name          = "${each.value.service.container_name}"
          containerPort = "${each.value.service.container_port}"
          hostPort      = "${each.value.service.container_port}"
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = false
      memory_reservation        = 100
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this[each.key].arn
    service = {
      client_alias = {
        port     = "${each.value.service.container_port}"
        dns_name = "${each.value.service.container_name}"
      }
      port_name      = "${each.value.service.container_name}"
      discovery_name = "${each.value.service.container_name}"
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_group_arns[each.value.index]
      container_name   = "${each.value.service.container_name}"
      container_port   = "${each.value.service.container_port}"
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = "${each.value.service.container_port}"
      to_port                  = "${each.value.service.container_port}"
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

