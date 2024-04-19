
output "smtp_host" {
  value = var.create_smtp_user ? "email-smtp.${local.aws_region}.amazonaws.com" : null
}

output "smtp_password" {
  value = one(aws_iam_access_key.smtp[*].ses_smtp_password_v4)
}

output "smtp_username" {
  value = one(aws_iam_access_key.smtp[*].id)
}

output "ecs_role_arn" {
  value = one(aws_iam_role.ecs[*].arn)
}
