terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {
    region         = "us-west-2"
    bucket         = "testcaseformultiservicebackend-test-terraform-state"
    key            = "terraformmultiservice.tfstate"
    dynamodb_table = "testcaseformultiservicebackend-test-terraform-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }  
}