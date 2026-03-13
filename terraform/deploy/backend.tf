terraform {
  backend "s3" {
    bucket         = "galin-demo-terraform-state"
    key            = "ecs-galin-demo/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "galin-demo-terraform-locks"
    encrypt        = true
  }
}