resource "aws_subnet" "base_project_db_subnet" {
  count             = var.subnet_count.db_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.db_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_stg_${count.index}" : "geacco_app_db_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "base_project_db_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_route_table_stg" : "geacco_app_db_route_table_prod"
  }
}

resource "aws_route_table_association" "base_project_db_route_table_association" {
  count          = var.subnet_count.db_private
  subnet_id      = aws_subnet.base_project_db_subnet[count.index].id
  route_table_id = aws_route_table.base_project_db_route_table.id
}

resource "aws_security_group" "RDS_security_group" {
  name        = terraform.workspace == "stg" ? "RDS_security_group_stg" : "RDS_security_group_prod"
  description = "A security group for the RDS database"
  vpc_id      = aws_vpc.base_project_VPC.id

  ingress {
    description     = "Allow RDS traffic from the web only (EC2)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id, aws_security_group.ECS_security_group.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_rds_security_group_stg" : "geacco_app_rds_security_group_prod"
  }
}

resource "aws_db_subnet_group" "geacco_db_subnet_group" {
  name       = terraform.workspace == "stg" ? "geacco_app_db_subnet_group_stg" : "geacco_app_db_subnet_group_prod"
  subnet_ids = [for subnet in aws_subnet.base_project_db_subnet : subnet.id]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_db_subnet_group_stg" : "geacco_app_db_subnet_group_prod"
  }
}

resource "aws_db_instance" "geacco_db_instance" {
  identifier             = terraform.workspace == "stg" ? "geaccodbstg" : "geaccodbprod"
  allocated_storage      = var.settings.database.allocated_storage
  db_name                = terraform.workspace == "stg" ? "geacco_db_stg" : "geacco_db_prod"
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  username               = local.db_creds.username
  password               = local.db_creds.password
  db_subnet_group_name   = aws_db_subnet_group.geacco_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.RDS_security_group.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
}

resource "aws_security_group" "EC_security_group" {
  name        = terraform.workspace == "stg" ? "EC_security_group_stg" : "EC_security_group_prod"
  vpc_id      = aws_vpc.base_project_VPC.id

  ingress {
    description     = "Allow EC traffic from the web only (EC2)"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id, aws_security_group.ECS_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_replication_group" "base_project_EC_replication_group" {
  replication_group_id       = terraform.workspace == "stg" ? "baseprojectECclusterstg" : "baseprojectECclusterprod"
  description = terraform.workspace == "stg" ? "Redis from Geacco app stg" : "Redis from Geacco app prod"

  node_type            = "cache.t2.micro"
  port                 = 6379
  engine_version = "5.0.6"


  subnet_group_name          = aws_elasticache_subnet_group.base_project_EC_subnet_group.name
  security_group_ids = [aws_security_group.EC_security_group.id]

  num_node_groups         = 1
  replicas_per_node_group = 1

}

resource "aws_subnet" "base_project_EC_subnet" {
  count             = var.subnet_count.EC_private
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.EC_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_EC_subnet_stg_${count.index}" : "geacco_app_EC_subnet_prod_${count.index}"
  }
}

resource "aws_route_table" "base_project_EC_route_table" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_EC_route_table_stg" : "geacco_app_EC_route_table_prod"
  }
}

resource "aws_route_table_association" "base_project_EC_route_table_association" {
  count          = var.subnet_count.EC_private
  subnet_id      = aws_subnet.base_project_EC_subnet[count.index].id
  route_table_id = aws_route_table.base_project_EC_route_table.id
}

resource "aws_elasticache_subnet_group" "base_project_EC_subnet_group" {
  name       = terraform.workspace == "stg" ? "base-project-EC-stg" : "base-project-EC-prod"
  subnet_ids = [for subnet in aws_subnet.base_project_EC_subnet : subnet.id]
}
