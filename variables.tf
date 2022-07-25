variable "vpc" {
  type        = string
  description = "VPC to deploy to"
  default     = "vpc-0a2a83d4e068c74c6"
}

variable "home_ip" {
  type        = string
  description = "My Home IP"
  default     = "98.243.123.20/32"
}

variable "ami" {
  type        = string
  description = "AMI to be used"
  default     = "ami-00ddb0e5626798373"
}

variable "environment" {
  type        = string
  description = "environment"
  default     = "dev"
}

variable "instance_size" {
  type = string
  description = "The instance size"
  default = "t3a.medium"
}