variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "container_image" {
  description = "Container image used by ECS task"
  type        = string
  default     = "nginx:latest"
}

variable "terraform_user" {
  description = "The IAM user that will be attached to ECR policy"
  type        = string
  default     = ""
}