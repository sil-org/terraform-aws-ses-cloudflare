variable "email_from_address" {
  description = "email address used in the FROM header of messages, also used to set the email domain"
  type        = string
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
  default     = "v=spf1 include:amazonses.com -all"
}

variable "create_dmarc_record" {
  description = "enable creation of a DMARC record for the email domain"
  type        = string
  default     = true
}

variable "dmarc_record_text" {
  description = "text string for the email domain DMARC record"
  type        = string
  default     = "v=DMARC1; p=none; sp=reject"
}

variable "mail_from_subdomain" {
  description = "subdomain of the email domain used for creating the custom mail-from domain"
  type        = string
  default     = "bounce"
}

variable "extra_tags" {
  description = "extra tags to include in Cloudflare tags; managed_by:\"terraform\" and workspace:terraform.workspace are included automatically"
  type        = map(string)
  default     = {}
}
