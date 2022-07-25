terraform {
  backend "s3" {
    bucket               = "troydieter.com-tfstate"
    key                  = "cachet-tf-ec2.tfstate"
    workspace_key_prefix = "cachet-tf-ec2-tfstate"
    region               = "us-east-1"
  }
}
