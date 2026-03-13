provider "aws" {
  region = "eu-central-1"
}

# --- S3 Bucket for Terraform state ---
resource "aws_s3_bucket" "terraform_state" {
  bucket = "galin-demo-terraform-state"
  force_destroy = true
}

# --- S3 Bucket for Terraform state logs ---
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "galin-demo-terraform-state-logs"
  force_destroy = true
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "terraform-state-logs/"
}

# Enable public access block for state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create a CMK for S3 state encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Enable server-side encryption using CMK
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
  }
}

# Public access block for logs bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for logs bucket
resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create a CMK for S3 state encryption
resource "aws_kms_key" "terraform_state_logs" {
  description             = "KMS key for Terraform state bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Enable server-side encryption for logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state_logs.arn
    }
  }
}

# --- DynamoDB Table for Terraform state locking ---
# CMK for DynamoDB encryption
resource "aws_kms_key" "terraform_locks" {
  description             = "KMS key for Terraform DynamoDB lock table"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# DynamoDB table
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "galin-demo-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_locks.arn
  }

  point_in_time_recovery {
    enabled = true
  }
}
