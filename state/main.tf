terraform {
  required_version = ">= 0.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }

  
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

module "terraform_state_backend" {
  source = "cloudposse/tfstate-backend/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version     = "x.x.x"
  namespace  = "testcaseformultiservicebackend"
  stage      = "test"
  name       = "terraform"
  attributes = ["state"]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}


variable "region" {
  description = "The AWS region in which resources are set up."
  type        = string
  default     = "us-west-2"
}
