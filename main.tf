locals {
  aws_account      = data.aws_caller_identity.this.account_id
  aws_region       = data.aws_region.current.name
  email_domain     = split("@", var.email_from_address)[1]
  mail_from_domain = "${var.mail_from_subdomain}.${local.email_domain}"
}

data "aws_caller_identity" "this" {}

data "aws_region" "current" {}

data "cloudflare_zone" "this" {
  name = var.cloudflare_domain == "" ? local.email_domain : var.cloudflare_domain
}

/*
 * Domain Identity
 */
resource "aws_ses_domain_identity" "this" {
  domain = local.email_domain
}

# DKIM records
resource "aws_ses_domain_dkim" "this" {
  domain = one(aws_ses_domain_identity.this[*].domain)
}

resource "cloudflare_record" "ses_dkim" {
  count = 3

  name    = "${element(one(aws_ses_domain_dkim.this[*].dkim_tokens), count.index)}._domainkey.${local.email_domain}"
  type    = "CNAME"
  zone_id = data.cloudflare_zone.this.id
  content = "${element(one(aws_ses_domain_dkim.this[*].dkim_tokens), count.index)}.dkim.amazonses.com"
  tags    = var.cloudflare_tags
  comment = "DKIM record for email authentication"
}

# TXT record for SPF
resource "cloudflare_record" "spf" {
  count = var.create_spf_record ? 1 : 0

  name    = local.email_domain
  type    = "TXT"
  zone_id = data.cloudflare_zone.this.id
  content = var.spf_record_text
  tags    = var.cloudflare_tags
  comment = "SPF record for email authentication"
}

# DMARC record
resource "cloudflare_record" "dmarc" {
  count = var.create_dmarc_record ? 1 : 0

  name    = "_dmarc.${local.email_domain}"
  type    = "TXT"
  zone_id = data.cloudflare_zone.this.id

  content = var.dmarc_record_text

  comment = "DMARC record for ${local.email_domain}"
  tags    = var.cloudflare_tags
}

/*
 * Custom Mail From domain and DNS records
 */
resource "aws_ses_domain_mail_from" "this" {
  domain           = local.email_domain
  mail_from_domain = local.mail_from_domain

  depends_on = [
    aws_ses_domain_identity.this
  ]
}

resource "cloudflare_record" "from_domain_mx" {
  name     = local.mail_from_domain
  type     = "MX"
  zone_id  = data.cloudflare_zone.this.id
  priority = 10
  content  = "feedback-smtp.${local.aws_region}.amazonses.com"
  tags     = var.cloudflare_tags
  comment  = "MX record for ${local.email_domain} bounce messages"
}

resource "cloudflare_record" "from_domain_spf" {
  name    = local.mail_from_domain
  type    = "TXT"
  zone_id = data.cloudflare_zone.this.id
  content = "\"v=spf1 include:amazonses.com ~all\""
  tags    = var.cloudflare_tags
  comment = "SPF record for ${local.email_domain} bounce messages"
}

/*
 * SMTP user and access key
 */
resource "aws_iam_user" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  name = var.smtp_user_name == "" ? "${local.email_domain}-smtp-user" : var.smtp_user_name
}

resource "aws_iam_access_key" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  user = one(aws_iam_user.smtp[*].name)
}

resource "aws_iam_user_policy" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  name = "SMTP-User"
  user = one(aws_iam_user.smtp[*].name)

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ses:sendEmail",
            "ses:sendRawEmail",
          ]
          Resource = aws_ses_domain_identity.this.arn,
          Condition = {
            StringEquals = {
              "ses:FromAddress" = var.email_from_address
            }
          }
        }
      ]
    }
  )
}

/*
 * Create ECS role
 */
resource "aws_iam_role" "ecs" {
  count = var.create_ecs_role ? 1 : 0

  name = var.ecs_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com",
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${local.aws_region}:${local.aws_account}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = local.aws_account
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses" {
  count = var.create_ecs_role ? 1 : 0

  name = "ses"
  role = one(aws_iam_role.ecs[*].name)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "SendEmail"
      Effect   = "Allow"
      Action   = "ses:SendEmail"
      Resource = "*"
      Condition = {
        StringEquals = {
          "ses:FromAddress" = var.email_from_address
        }
      }
    }]
  })
}

/*
 * Optional: SNS topic for SES Bounce notifications
 */
resource "aws_sns_topic" "ses_bounces" {
  count = var.create_bounce_topic ? 1 : 0

  kms_master_key_id = "alias/aws/sns"

  display_name = coalesce(
    var.bounce_topic_name,
    "${local.email_domain} SES bounces"
  )
  name = coalesce(
    var.bounce_topic_name,
    "${replace(local.email_domain, "/[^A-Za-z0-9-_]/", "-")}-ses-bounces"
  )
}

resource "aws_sns_topic_policy" "ses_publish" {
  count = var.create_bounce_topic ? 1 : 0

  arn = one(aws_sns_topic.ses_bounces[*].arn)
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSESPublish",
        Effect = "Allow",
        Principal = {
          Service = "ses.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = one(aws_sns_topic.ses_bounces[*].arn),
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = local.aws_account
          },
          StringLike = {
            "AWS:SourceArn" = aws_ses_domain_identity.this.arn
          }
        }
      }
    ]
  })
}

resource "aws_ses_identity_notification_topic" "bounce" {
  count = var.create_bounce_topic ? 1 : 0

  identity          = one(aws_ses_domain_identity.this[*].arn)
  notification_type = "Bounce"
  topic_arn         = one(aws_sns_topic.ses_bounces[*].arn)
}
