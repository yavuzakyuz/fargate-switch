locals {
  ecs_services = {
    developer1 = {
      container_name = "ecsdemo"
      container_port = 80
      image_tag = "2.4-22.04_beta"
      domain = "developer1.${local.domain}"
    },
    developer2 = {
      container_name = "ecsdemo"
      container_port = 80
      image_tag = "latest"
      domain = "developer2.${local.domain}"
    }
  }
}
