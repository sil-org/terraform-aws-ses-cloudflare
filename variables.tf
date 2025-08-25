variable "email_from_address" {
  description = "email address used in the FROM header of messages, also used to set the email domain"
  type        = string
}

variable "cloudflare_domain" {
  description = "domain defined in a Cloudflare zone for the DNS records to be created, uses the email_from_address domain if not specified"
  type        = string
  default     = ""
}

variable "mail_from_subdomain" {
  description = "subdomain of the email domain used for creating the custom mail-from domain"
  type        = string
  default     = "bounce"
}

variable "create_smtp_user" {
  description = "create an IAM user and key for sending by SMTP"
  type        = bool
  default     = false
}

variable "smtp_user_name" {
  description = "user name of the AWS IAM user with permissions on SES, which is also used for SMTP credentials"
  type        = string
  default     = ""
}

variable "create_ecs_role" {
  description = "create an ECS role for sending by SMTP"
  type        = bool
  default     = false
}

variable "ecs_role_name" {
  description = "name of the ECS role with permissions on SES"
  type        = string
  default     = ""
}

variable "create_spf_record" {
  description = "enable creation of an SPF record for the email domain"
  type        = string
  default     = true
}

variable "spf_record_text" {
  description = "text string for the email domain SPF record"
  type        = string
  default     = "\"v=spf1 include:amazonses.com -all\""
}

variable "create_dmarc_record" {
  description = "enable creation of a DMARC record for the email domain"
  type        = string
  default     = true
}

variable "dmarc_record_text" {
  description = "text string for the email domain DMARC record"
  type        = string
  default     = "\"v=DMARC1; p=none; sp=reject\""
}

variable "cloudflare_tags" {
  description = "tags to include in Cloudflare records; managed_by:\"terraform\" is included by default"
  type        = list(string)
  default = [
    "managed_by:terraform",
  ]
}

# New: SNS topic for SES bounces
variable "create_bounce_topic" {
  description = "create an SNS topic and configure SES to publish Bounce notifications to it"
  type        = bool
  default     = false
}

variable "bounce_topic_name" {
  description = "name for the SNS topic that receives SES bounce notifications; default uses <email_domain>-ses-bounces"
  type        = string
  default     = ""
}
