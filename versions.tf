
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    cloudflare = {
      version = "~> 4.0"
      source  = "cloudflare/cloudflare"
    }
  }
}
