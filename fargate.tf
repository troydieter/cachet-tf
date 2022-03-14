###############
# Fargate Resources
###############

module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = "${var.application}-${random_id.rando.hex}"
  type        = "application"
  internal    = false
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnets

  tags = local.common-tags
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = module.fargate_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = module.fargate.target_group_arn
    type             = "forward"
  }
}

resource "aws_security_group_rule" "task_ingress_8000" {
  security_group_id        = module.fargate.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8000
  to_port                  = 8000
  source_security_group_id = module.fargate_alb.security_group_id
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = module.fargate_alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_efs_file_system" "efs" {
  encrypted = true
  tags = local.common-tags
}

resource "aws_efs_access_point" "efs" {
  file_system_id = aws_efs_file_system.efs.id
}


resource "aws_ecs_cluster" "cluster" {
  name = "${var.application}-cluster-${random_id.rando.hex}"
}

module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "5.4.0"

  name_prefix          = var.name_prefix
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.intra_subnets
  lb_arn               = module.fargate_alb.arn
  cluster_id           = aws_ecs_cluster.cluster.id
  task_container_image = "crccheck/hello-world:latest"

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = true

  // port, default protocol is HTTP
  task_container_port = 8000

  task_container_port_mappings = [
    {
      containerPort = 9000
      hostPort      = 9000
      protocol      = "tcp"
    }
  ]

  task_container_environment = {
    TEST_VARIABLE = "TEST_VALUE"
  }

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  efs_volumes = [{
    name            = "storage"
    file_system_id  = aws_efs_file_system.efs.id
    root_directory  = "/"
    mount_point     = "/opt/files/"
    readOnly        = false
    access_point_id = aws_efs_access_point.efs.id
  }]

  tags = local.common-tags
}