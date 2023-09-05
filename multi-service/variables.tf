variable "my_access_key" {
  description = "The AWS Access Key"
  type        = string
  sensitive   = true  # Marking as sensitive to ensure Terraform doesn't log the value
}

variable "my_secret_key" {
  description = "The AWS Secret Key"
  type        = string
  sensitive   = true  # Marking as sensitive to ensure Terraform doesn't log the value
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-west-2"
}
