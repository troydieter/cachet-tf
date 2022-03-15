variable "aws-profile" {
  description = "AWS profile for provisioning the resources"
  type        = string
}

variable "aws_region" {
  description = "AWS Region- Defaulted to us-east-1"
  default     = "us-east-1"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "application" {
  description = "Cachet"
  type        = string
  default     = "cachet"
}

variable "domain_name" {
  description = "Top Level Domain Name to be used"
  type        = string
}

variable "zone_id" {
  description = "Route53 Zone ID"
  type        = string
}