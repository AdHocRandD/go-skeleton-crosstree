data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = var.name_prefix
  type        = "application"
  internal    = false
  vpc_id      = var.vpc_id
  subnet_ids  = data.aws_subnets.main.ids

  tags = var.tags
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

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"
}

# resource "aws_secretsmanager_secret" "task_container_secrets" {
#   name       = var.name_prefix
#   kms_key_id = var.task_container_secrets_kms_key
# }

# resource "aws_secretsmanager_secret_version" "task_container_secrets" {
#   secret_id     = aws_secretsmanager_secret.task_container_secrets.id
#   secret_string = "Super secret and important string"
# }

# data "aws_secretsmanager_secret" "task_container_secrets" {
#   arn = aws_secretsmanager_secret.task_container_secrets.arn
# }

# data "aws_kms_key" "task_container_secrets" {
#   key_id = data.aws_secretsmanager_secret.task_container_secrets.kms_key_id
# }

module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "7.1.0"

  name_prefix          = var.name_prefix
  vpc_id               = var.vpc_id
  private_subnet_ids   = var.private_subnet_ids
  lb_arn               = module.fargate_alb.arn
  cluster_id           = aws_ecs_cluster.cluster.id
  task_container_image = var.task_container_image

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = true

  // port, default protocol is HTTP
  task_container_port = var.task_container_port

  task_container_environment = var.task_container_environment

  # task_container_secrets_kms_key = data.aws_kms_key.task_container_secrets.key_id

  # task_container_secrets = var.task_container_secrets

  health_check = var.health_check

  tags = var.tags
}
