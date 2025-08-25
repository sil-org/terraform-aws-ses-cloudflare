module "minimal" {
  source = "../"

  email_from_address = "no_reply@example.com"
}

module "all" {
  source = "../"

  email_from_address  = "no_reply@example.com"
  create_smtp_user    = true
  smtp_user_name      = "smtp-user-example-com"
  create_ecs_role     = true
  ecs_role_name       = "ecs-role-example-com"
  create_spf_record   = true
  spf_record_text     = "v=spf1 include:amazonses.com -all"
  create_dmarc_record = true
  dmarc_record_text   = "v=DMARC1; p=none; sp=reject"
  mail_from_subdomain = "bounce"
  cloudflare_tags     = ["customer:Acme, Inc."]
  create_bounce_topic = true
  bounce_topic_name   = "example-ses-bounces"
}

provider "aws" {
  region = local.aws_region
}

locals {
  aws_region = "us-east-1"
}

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
