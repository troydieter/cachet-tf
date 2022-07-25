##################################################################
# Bootstrap
##################################################################

locals {
  user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo curl -L "https://github.com/docker/compose/releases/download/2.7.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
EOF
}

# SSM
data "aws_iam_policy" "required-policy" {
  name = "AmazonSSMManagedInstanceCore"
}

# IAM Role
resource "aws_iam_role" "ssm-role" {
  name = "cachet-${random_id.rando.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach-ssm" {
  role       = aws_iam_role.ssm-role.name
  policy_arn = data.aws_iam_policy.required-policy.arn
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "aws_ssm_cachet-${random_id.rando.hex}"
  role = aws_iam_role.ssm-role.name
}


##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_vpc" "default" {
  id = var.vpc
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Reach = "public"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "cachet-sg-${random_id.rando.hex}"
  description = "cachet SG"
  vpc_id      = data.aws_vpc.default.id
  ingress_with_cidr_blocks = [
        {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All Traffic"
      cidr_blocks = var.home_ip
    }
  ]
  egress_rules = ["all-all"]
  tags         = local.common-tags
}

resource "aws_kms_key" "this" {
  tags = local.common-tags
}

resource "aws_network_interface" "this" {
  count = 1

  subnet_id = tolist(data.aws_subnet_ids.all.ids)[count.index]
  tags      = local.common-tags
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "cachet-${random_id.rando.hex}"
  ami                         = var.ami
  instance_type               = var.instance_size
  subnet_id                   = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  key_name                    = "cachet"
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = true
  monitoring                  = true

  user_data_base64 = base64encode(local.user_data)

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 30
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 5
      encrypted   = true
      kms_key_id  = aws_kms_key.this.arn
    }
  ]

  tags = local.common-tags
}

output "ids" {
  description = "List of IDs of instances"
  value       = module.ec2.id
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances"
  value       = module.ec2.public_dns
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = module.ec2.public_ip
}

output "unique_id" {
  description = "Unique ID to identify these resources"
  value       = random_id.rando.hex
}