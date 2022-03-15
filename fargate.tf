###############
# Fargate Resources
###############

module "fargate" {
  source  = "cn-terraform/ecs-fargate/aws"
  version = "2.0.33"
  name_prefix         = "${var.application}"
  vpc_id              = module.vpc.vpc_id
  container_image     = "ubuntu"
  container_name      = "test"
  public_subnets_ids  = module.vpc.public_subnets
  private_subnets_ids = module.vpc.intra_subnets
  lb_internal = false
  

  tags = local.common-tags
}