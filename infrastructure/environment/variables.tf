variable "IMAGE_TAG" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "REPOSITORY_URL_NGINX" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "REPOSITORY_URL_CELERY_WORKER" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "REPOSITORY_URL_CELERY_BEAT" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "IMAGE_TAG_NGINX" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "IMAGE_TAG_CELERY_WORKER" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "REPOSITORY_URL" {
  description = "ECR Image tag"
  type        = string
  default     = "latest"
}

variable "IP" {
  type        = string
  default     = "186.169.54.167"
}

variable "subnet_count" {
  description = "Number of subnet"
  type        = map(number)
  default = {
    db_private    = 2
    cloud_public  = 2
    EC_private = 2
  }
}

variable "settings" {
  description = "Configuration settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 10
      engine              = "postgres"
      engine_version      = "13.11"
      instance_class      = "db.t3.micro"
      skip_final_snapshot = true
    },
    "web_app" = {
      count         = 1
      instance_type = "t3.medium"
    }
  }
}

variable "cloud_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "db_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24"
  ]
}

variable "EC_subnet_cidr_block" {
  description = "Available CIDR blocks for subnets"
  type        = list(string)
  default = [
    "10.0.9.0/24",
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "iam_policy_arn" {
  description = "IAM Policy to be attached to role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  ]
}

variable "iam_policy_arn_task_ecs" {
  description = "IAM Policy to be attached to ecs task role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  ]
}

variable "DJANGO_SUPERUSER_USERNAME" {
  description = "Username for superuser"
  type        = string
  default = ""
  sensitive   = true
}

variable "DJANGO_SUPERUSER_EMAIL" {
  description = "Email for superuser"
  type        = string
  default = ""
  sensitive   = true
}

variable "DJANGO_SUPERUSER_PASSWORD" {
  description = "Password for superuser"
  type        = string
  default = ""
  sensitive   = true
}

variable "stg_domain_name" {
  type        = string
  description = "The stage domain name for the website."
  default     = "geaccoapp.stg.com"
}

variable "prod_domain_name" {
  type        = string
  description = "The domain name for the website."
  default     = "geaccoapp.com"
}

variable "TASK_HOST_PORT" {
  type = string
}
