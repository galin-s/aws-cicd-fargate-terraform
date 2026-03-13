provider "aws" {
  region = var.aws_region
}
# --- VPC ---
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  # checkov:skip=CKV_TF_1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  

  name = "galin-demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a","eu-central-1b"]
  private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"]

  enable_nat_gateway  = false
  single_nat_gateway  = false
}

# --- ECR repository ---
resource "aws_ecr_repository" "app" {
  name = "galin-demo-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }
}

resource "aws_kms_key" "ecr" {

  # checkov:skip=CKV2_AWS_64
  description             = "KMS key for ECR repository"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}


# --- ECS Cluster ---
resource "aws_ecs_cluster" "cluster" {
  name = "galin-demo-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --- ECS Task (Fargate) ---
resource "aws_ecs_task_definition" "task" {
  family                   = "galin-demo"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy
  ]

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = "app"
      image = var.container_image
      essential = true
      readonlyRootFilesystem = true 

      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])

  lifecycle {
    create_before_destroy = true
  }
}

# --- ECS Service (Fargate) ---
resource "aws_ecs_service" "service" {
  # checkov:skip=CKV_AWS_333
  name            = "galin-demo-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  depends_on = [
    aws_ecs_task_definition.task
  ]

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }
}

# --- User Policy ---
resource "aws_iam_user_policy_attachment" "ecr_poweruser" {

  # checkov:skip=CKV_AWS_40
  count      = var.terraform_user != "" ? 1 : 0
  user       = var.terraform_user
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# --- Security group for ECS ---
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow HTTP traffic"
  vpc_id      = module.vpc.vpc_id
  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all HTTP inbound traffic"
  }
  # tfsec:ignore:aws-ec2-no-public-egress-sgr, aws-ec2-restrict-egress-to-specific-ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #checkov:skip=CKV_AWS_382
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# --- Task Execution Role ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- Task Execution Policy ---
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
