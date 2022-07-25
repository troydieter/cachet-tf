data "aws_caller_identity" "current" {}

locals {
  common-tags = {
    "project"     = "cachet-tf-ec2"
    "environment" = var.environment
    "id"          = random_id.rando.hex
  }
}

resource "random_id" "rando" {
  byte_length = 2
}

resource "random_integer" "rando_int" {
  min = 1
  max = 100
}

provider "aws" {
  region = "us-east-1"
}
