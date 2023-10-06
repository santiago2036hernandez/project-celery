variable "environment_server" {
  type = string
  default = "prod"
  description = "Enviroment to deploy"
}


resource "aws_security_group" "ALB_security_group" {
  name        = terraform.workspace == "stg" ? "ALB_security_group_stg" : "ALB_security_group_prod"
  description = "A security group for the ALB database"
  vpc_id      = aws_vpc.base_project_VPC.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_alb_security_group_stg" : "geacco_app_alb_security_group_prod"
  }
}

resource "aws_lb_target_group" "base_project_alb_target_group" { //Copy
  name        = terraform.workspace == "stg" ? "geacco-alb-target-group-stg" : "geacco-alb-target-group-prod"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_project_VPC.id
  deregistration_delay = 5

  lifecycle { create_before_destroy=true }

  health_check {
    path = "/health"
    healthy_threshold = 2
    interval = 5
    timeout = 2
    matcher = "200,301,302"
  }

}

resource "aws_lb" "base_project_alb" { // Copy
  name               = terraform.workspace == "stg" ? "geacco-ALB-stg" : "geacco-ALB-prod"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_security_group.id]
  subnets            = [for subnet in aws_subnet.base_project_cloud_subnet : subnet.id]
}

resource "aws_lb_listener" "base_project_alb_listener" {
  load_balancer_arn = aws_lb.base_project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.base_project_alb_target_group.id}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "base_project_alb_listener_https" { # Copy
  load_balancer_arn = aws_lb.base_project_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm-pca:us-east-1:460314545847:certificate-authority/cc6f8c5d-3b53-4edc-9676-176ff89d56a9"

  default_action {
    target_group_arn = "${aws_lb_target_group.base_project_alb_target_group.id}"
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "base_project_ecs_cluster" { //Copy
  name = terraform.workspace == "stg" ? "base-project-ecs-cluster-stg" : "base-project-ecs-cluster-prod"
}

resource "aws_ecs_task_definition" "base_project_ecs_task_definition" { #   Copy
  family                   = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod"
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.base_project_ecs_execution_iam_role.arn
  requires_compatibilities = ["EC2"]
  volume {
    name = "static_volume"
  }

  container_definitions = jsonencode([
    {
      essential   = true
      name        = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod"
      image       = "${var.REPOSITORY_URL}:${var.IMAGE_TAG}"
      memoryReservation = 1001
      environment = [
      # {
      #   name  = "DEBUG", // Set when setup instance for the first time
      #   value = "on"
      # },
      {
        name  = "DATABASE_URL",
        value = "postgres://${local.db_creds.username}:${local.db_creds.password}@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}"
      },
      {
        name  = "SECRET_KEY",
        value = local.secret_keys.SECRET_KEY
      },
      {
        name  = "REDIS_URL",
        value = "redis://${aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address}:6379/0"
      },
      {
        name  = "POSTGRES_PASSWORD",
        value = "${local.db_creds.password}"
      },
      # {
      #   name  = "ENV",
      #   value = "build" //Change for build when db migration hasn't been done
      # },
      {
        name  = "ENV",
        value = var.environment_server //Change for build when db migration hasn't been done
      },
      {
        name  = "DJANGO_SUPERUSER_PASSWORD",
        value = "${var.DJANGO_SUPERUSER_PASSWORD}"
      },
      {
        name  = "DJANGO_SUPERUSER_USERNAME",
        value = "${var.DJANGO_SUPERUSER_USERNAME}"
      },
      {
        name  = "DJANGO_SUPERUSER_EMAIL",
        value = "${var.DJANGO_SUPERUSER_EMAIL}"
      }
      ],
      mountPoints = [
          {
              "sourceVolume": "static_volume",
              "containerPath": "/app/static",
              "readOnly": false
          }
      ],
      portMappings = [
        {
          containerPort = 8000,
          hostPort      = tonumber("${var.TASK_HOST_PORT}"),
          protocol      = "tcp"
        }
      ],
      entryPoint = ["/app/setup_environment"],
      logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = terraform.workspace == "stg" ? "base_project_image_logs-stg" : "base_project_image_logs-prod",
            awslogs-create-group = "true",
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    },
    {
      essential   = true
      name        = terraform.workspace == "stg" ? "base-project-celery-worker-image-stg" : "base-project-celery-worker-image-prod"
      memoryReservation = 1000
      image       = "${var.REPOSITORY_URL_CELERY_WORKER}:${var.REPOSITORY_URL_CELERY_WORKER}"
      volumesFrom = [
      {
          sourceContainer = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod",
          readOnly = false
      }
      ]
      portMappings = [
        {
          containerPort = 5555, // Celery port of docker image
          hostPort      = 0,
          protocol      = "tcp"
        }
      ]
      environment = [
        {
        name  = "DATABASE_URL",
        value = "postgres://${local.db_creds.username}:${local.db_creds.password}@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}"
      },
      {
        name  = "SECRET_KEY",
        value = local.secret_keys.SECRET_KEY
      },
      {
        name  = "REDIS_URL",
        value = "redis://${aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address}:6379/0"
      },
      {
        name  = "POSTGRES_PASSWORD",
        value = "${local.db_creds.password}"
      },
      # {
      #   name  = "ENV",
      #   value = "build" //Change for build when db migration hasn't been done
      # },
      {
        name  = "ENV",
        value = var.environment_server //Change for build when db migration hasn't been done
      },
      {
        name  = "DJANGO_SUPERUSER_PASSWORD",
        value = "${var.DJANGO_SUPERUSER_PASSWORD}"
      },
      {
        name  = "DJANGO_SUPERUSER_USERNAME",
        value = "${var.DJANGO_SUPERUSER_USERNAME}"
      },
      {
        name  = "DJANGO_SUPERUSER_EMAIL",
        value = "${var.DJANGO_SUPERUSER_EMAIL}"
      },
      ]
      
      logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = terraform.workspace == "stg" ? "base_project_celery_worker_image_logs_stg" : "base_project_celery_worker_image_logs_prod",
            awslogs-create-group = "true",
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    },
    {
      essential   = true
      name        = terraform.workspace == "stg" ? "base-project-celery-beat-image-stg" : "base-project-celery-beat-image-prod"
      memoryReservation = 1000
      image       = "${var.REPOSITORY_URL_CELERY_BEAT}:${var.REPOSITORY_URL_CELERY_BEAT}"
      volumesFrom = [
      {
          sourceContainer = terraform.workspace == "stg" ? "base-project-image-stg" : "base-project-image-prod",
          readOnly = false
      }
      ]
      portMappings = [
        {
          containerPort = 5556, // Celery port of docker image
          hostPort      = 0,
          protocol      = "tcp"
        }
      ]
      environment = [
        {
        name  = "DATABASE_URL",
        value = "postgres://${local.db_creds.username}:${local.db_creds.password}@${aws_db_instance.geacco_db_instance.address}:${aws_db_instance.geacco_db_instance.port}/${aws_db_instance.geacco_db_instance.db_name}"
      },
      {
        name  = "SECRET_KEY",
        value = local.secret_keys.SECRET_KEY
      },
      {
        name  = "REDIS_URL",
        value = "redis://${aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address}:6379/0"
      },
      {
        name  = "POSTGRES_PASSWORD",
        value = "${local.db_creds.password}"
      },
      # {
      #   name  = "ENV",
      #   value = "build" //Change for build when db migration hasn't been done
      # },
      {
        name  = "ENV",
        value = var.environment_server //Change for build when db migration hasn't been done
      },
      {
        name  = "DJANGO_SUPERUSER_PASSWORD",
        value = "${var.DJANGO_SUPERUSER_PASSWORD}"
      },
      {
        name  = "DJANGO_SUPERUSER_USERNAME",
        value = "${var.DJANGO_SUPERUSER_USERNAME}"
      },
      {
        name  = "DJANGO_SUPERUSER_EMAIL",
        value = "${var.DJANGO_SUPERUSER_EMAIL}"
      },
      ]
      
      logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group = terraform.workspace == "stg" ? "base_project_celery_worker_image_logs_stg" : "base_project_celery_worker_image_logs_prod",
            awslogs-create-group = "true",
            awslogs-region = "us-east-1",
            awslogs-stream-prefix = "ecs",
          }
      },
    }
  ])
}

resource "aws_iam_role" "base_project_ecs_execution_iam_role" {
  name               = terraform.workspace == "stg" ? "base-project-ecs-task-role-stg" : "base-project-ecs-task-role-prod"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}


resource "aws_iam_role_policy_attachment" "base_project_ecs_task_role_policy_attachment" {
  count = length(var.iam_policy_arn_task_ecs)
  role  = aws_iam_role.base_project_ecs_execution_iam_role.name
  policy_arn = var.iam_policy_arn_task_ecs[count.index]
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_service" "base_project_ecs_service" { # Copy
  depends_on           = [aws_lb_listener.base_project_alb_listener]
  name                 = terraform.workspace == "stg" ? "base-project-ecs-service-stg" : "base-project-ecs-service-prod"

  launch_type          = "EC2"
  cluster              = aws_ecs_cluster.base_project_ecs_cluster.id
  force_new_deployment = true
  task_definition      = aws_ecs_task_definition.base_project_ecs_task_definition.arn
  desired_count = 1
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.base_project_alb_target_group.arn
    container_name   = terraform.workspace == "stg" ? "base-project-ngix-image-stg" : "base-project-ngix-image-prod"
    container_port   = 8001 // Celery port of docker image
  }
}

resource "aws_security_group" "ECS_security_group" { # Copy
  name        = terraform.workspace == "stg" ? "ECS_security_group_stg" : "ECS_security_group_prod"
  description = "A security group for the ECS"
  vpc_id      = aws_vpc.base_project_VPC.id
  ingress {
    description = "Allow all traffic throught HTTP"
    from_port   = "8001"
    to_port     = "8001"
    protocol    = "tcp"
    security_groups = [
      "${aws_security_group.ALB_security_group.id}",
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_ecs_security_group_stg" : "geacco_app_ecs_security_group_prod"
  }
}
