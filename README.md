# AWS Fargate Terraform CI/CD Demo

## Overview

This project demonstrates a **complete DevOps workflow** for deploying a containerized application to AWS using Infrastructure as Code and CI/CD automation.

The repository showcases how to:

- Provision infrastructure with **Terraform**
- Build and scan **Docker** images
- Push images to **Amazon ECR**
- Deploy containers to **Amazon ECS (Fargate)**
- Use **GitHub Actions** for CI/CD orchestration
- Secure Terraform state using **S3** and **DynamoDB**
- Perform automated security scans for code, dependencies, containers, and IaC
- Automatically clean up infrastructure

## Security Tools Used

This project integrates multiple DevSecOps security tools:

| Tool      | Purpose                                  |
|-----------|-----------------------------------------|
| Semgrep   | Static Application Security Testing     |
| Trivy     | Dependency and container vulnerability scanning |
| tfsec     | Terraform security scanning             |
| Checkov   | Infrastructure-as-Code policy scanning  |

Security checks are executed automatically during the CI/CD pipeline.
---

## Architecture

### Application Infrastructure

```
                  GitHub Actions
                        │
                        ▼
               Build Docker Image
                        │
                        ▼
                  Security Scans
        (Semgrep / Trivy / Checkov / tfsec)
                        │
                        ▼
                   Push to ECR
                        │
                        ▼
                Terraform Deployment
                        │
                        ▼
                Amazon ECS (Fargate)
                        │
                        ▼
                 Flask Application
```


### Terraform Backend Infrastructure
```
                    Terraform
                       │
                       ▼
                Amazon S3 Bucket
                (Terraform State)
                       │
                       ▼
                 DynamoDB Table
                 (State Locking)
```


---

## Project Structure

```
                ├── app
                │    └── app.py
                │
                ├── terraform
                │     │
                │     ├── bootstrap
                │     │     └── main.tf
                │     │
                │     └── deploy
                │           ├── main.tf
                │           ├── variables.tf
                │           └── backend.tf
                ├── .github
                │      │
                │      └── workflows
                │           ├── bootstrap.yml
                │           ├── deploy.yml
                │           └── destroy.yml
                │
                ├── Dockerfile
                │
                ├── requirements.txt
                │
                └── README.md
```


---

## Terraform Infrastructure

### Bootstrap Infrastructure

The **bootstrap module** provisions the Terraform backend resources:

- S3 bucket for Terraform state
- DynamoDB table for state locking
- KMS encryption keys
- Logging bucket for audit purposes

Security best practices implemented:

- Versioning enabled
- Server-side encryption using KMS
- Public access blocked
- Access logging enabled
- DynamoDB point-in-time recovery enabled

### Application Infrastructure

The **deploy module** provisions the runtime infrastructure:

- VPC using Terraform AWS VPC module
- ECS Cluster
- ECS Fargate Service
- ECR Repository
- IAM Roles and Policies
- Security Groups
- Container task definitions

---

## CI/CD Pipeline

The project uses **three GitHub Actions workflows**.

### 1. Bootstrap Workflow

Creates Terraform backend infrastructure.

**Steps:**

1. Checkout repository
2. Configure AWS credentials
3. Initialize Terraform
4. Create backend infrastructure
5. Upload Terraform state artifact
6. Trigger deployment workflow

---

### 2. Deploy Workflow

Builds and deploys the application.

**Pipeline stages:**

1. Checkout code
2. Run security scans
3. Build Docker image
4. Scan container image
5. Push image to ECR
6. Run Terraform deployment
7. Deploy ECS service
8. Trigger destroy workflow

---

### 3. Destroy Workflow

Automatically removes all infrastructure.

**Steps:**

1. Download Terraform state artifact
2. Destroy application infrastructure
3. Destroy backend infrastructure
4. Delete S3 buckets and DynamoDB table

---

## Application

The application is a minimal **Flask API** used for demonstration.

**Endpoints:**

| Endpoint | Description         |
|----------|-------------------|
| `/`      | Returns welcome message |
| `/health`| Health check endpoint  |

**Example response:**

```json
{
  "message": "Welcome to this project"
}
```

**Secrets needed in order to make the workflows work:**
1. AWS_SECRET_KEY
2. AWS_ACCESS_KEY
3. AWS_TERRAFORM_USER
4. AWS_ACCOUNT_ID
# aws-cicd-fargate-terraform