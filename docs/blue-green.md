

# Blue-Green Deployment on ECS with Terraform

Implementation of a blue-green deployment strategy on AWS ECS using Fargate. It enables conditional deployment of two environments, Blue and Green, to allow a seamless transition between application versions and easy rollbacks in case of issues.

Core components include: 
- Blue and Green Services in the ECS Cluster
- Dynamic Target Groups 
- Application Load Balancer with Forward Blocks

## Overview:

- **main.tf**: Contains global configurations, AWS provider setup, and the ECS cluster initialization.
- **alb.tf**: Configures the VPC, subnets, security groups, ALB, and its listeners. It sets up rules to route traffic to the appropriate deployment based on weightings.
- **blue_deployment.tf**: Details the resources and configurations for the Blue deployment, including the CloudMap namespace and the ECS service.
- **green_deployment.tf**: Similar to `blue_deployment.tf`, but for the Green deployment.

## Usage:

A step-by-step demo can be found in the docs folder of the repository. 

1. Deployment Control is done via locals in main.tf:
```bash
locals {
  deploy_green        = false
  deploy_blue         = true
  active_deployment   = "blue"
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
```

2. **Switch Routing Between Blue and Green**:
   To control which environment (Blue or Green) is active, modify the `active_deployment` variable in `main.tf`. `"blue"` to route traffic to the Blue Service or `"green"` for the Green Service.

3. **Rolling Back**:
   If there's a problem with the new production deployment, changing the `active_deployment` variable changes routing of the traffic instantly, as a result customers won't experience any service downtime.

4. **Deploying Changes**:
   When updating the application version, update the `blue_image` or `green_image` variables in `main.tf` to point to the new Docker image. After applying the changes, adjust the `active_deployment` variable to direct traffic to the new version.

5. **Possible pitfalls**:

   i. While performing a rollback, first step should include only changing the ALB routing without removing the problematic deployment. This will significantly decrease downtime. After the active_deployment is configured, then green_deployment or blue_deployment can be set false. 

```bash

pre-rollback state. Imagine blue is not working

---
deploy_green = true
deploy_blue = true
active_deployment = "blue"
---

Rollback Steps: 
 1. set active_deployment = "green"
 2. terraform apply 
--- rollback to green will happen in seconds --- 
 3. set deploy_blue false 
 4. terraform apply 
--- redundant blue service gets removed from the cluster --- 

   ```


---

