# terraform-aws-ses-cloudflare
Terraform module to create AWS and Cloudflare resources for SES

Includes:

* SES Domain Identity
* DKIM records for mail domain
* SES Domain MAIL FROM
* SPF and MX record for MAIL FROM domain
* Optional: AWS IAM user for SMTP mailing
* Optional: AWS IAM ECS Role
* Optional: SPF and DMARC records for mail domain
