terraform {
  backend "s3" {
    bucket         = "lathe-terraform-state-001"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

variable "aws_region" { default = "us-east-2" }
variable "aws_profile" { default = null }

# UNIQUE website bucket (NOT the tfstate bucket)
variable "site_bucket_name" {
  description = "Website S3 bucket name (private)"
  type        = string
}

variable "project" { default = "sell-my-stuff-frontend" }
variable "environment" { default = "dev" }

# Where your Vite build lives after `npm run build`
variable "artifact_dir" { default = "../dist" }
