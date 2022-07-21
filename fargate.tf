###############
# Fargate Resources
###############

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id

  subject_alternative_names = [
    "*.${var.domain_name}",
    "www.${var.domain_name}",
  ]

  wait_for_validation = true

  tags = local.common-tags
}
module "fargate" {
  source              = "cn-terraform/ecs-fargate/aws"
  #version             = "2.0.33"
  name_prefix         = var.application
  vpc_id              = module.vpc.vpc_id
  container_image     = "cachethq/docker"
  container_name      = "cachet-${random_id.rando.hex}"
  public_subnets_ids  = module.vpc.public_subnets
  private_subnets_ids = module.vpc.private_subnets
  lb_internal         = false
  port_mappings = [
    {
      "containerPort" : 80,
      "hostPort" : 80,
      "protocol" : "tcp"
    }
  ]
  lb_https_ports = {
    "default_https" : {
      "listener_port" : 443,
      "target_group_port" : 80
    }
  }
  map_environment = {
    "DB_HOST" = module.db.db_instance_address
  }
  default_certificate_arn = module.acm.acm_certificate_arn

  tags = local.common-tags
}