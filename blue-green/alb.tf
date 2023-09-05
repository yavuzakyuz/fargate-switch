################################################################################
# Supporting Resources
################################################################################

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "http-8080-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = local.tags
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  target_groups = concat(
    local.deploy_blue ? [
      {
        target_group_index = 0
        name               = "${local.name}-${local.container_name}-blue"
        backend_protocol   = "HTTP"
        backend_port       = local.container_port
        target_type        = "ip"
      }
    ] : [],
    local.deploy_green ? [
      {
        target_group_index = 1
        name               = "${local.name}-${local.container_name}-green"
        backend_protocol   = "HTTP"
        backend_port       = local.container_port
        target_type        = "ip"
      }
    ] : []
  )

  tags = local.tags
}



module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

# based on the active_deployment, we will forward traffic to the appropriate target group

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = module.alb.lb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = local.deploy_blue ? [1] : []
        content {
          arn    = element([for arn in module.alb.target_group_arns : arn if length(regexall("${local.name}-${local.container_name}-blue", arn)) > 0], 0)
          weight = local.active_deployment == "blue" ? 999 : (local.deploy_green ? 1 : 999) # ensure this value is between 1 and 999
        }
      }

      dynamic "target_group" {
        for_each = local.deploy_green ? [1] : []
        content {
          arn    = element([for arn in module.alb.target_group_arns : arn if length(regexall("${local.name}-${local.container_name}-green", arn)) > 0], 0)
          weight = local.active_deployment == "green" ? 999 : (local.deploy_blue ? 1 : 999) # ensure this value is between 1 and 999
        }
      }

      stickiness {
        enabled  = true
        duration = 1 # ensure this value is between 1 and 604800
      }
    }
  }
}