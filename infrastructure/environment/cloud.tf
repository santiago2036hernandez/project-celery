resource "aws_subnet" "base_project_cloud_subnet" {
  count             = var.subnet_count.cloud_public
  vpc_id            = aws_vpc.base_project_VPC.id
  cidr_block        = var.cloud_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_cloud_subnet_stg_${count.index}" : "geacco_app_cloud_subnet_prod_${count.index}"
  }
}

resource "aws_internet_gateway" "base_project_gw" {
  vpc_id = aws_vpc.base_project_VPC.id

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_internet_gateway_stg" : "geacco_app_internet_gateway_prod"
  }
}

resource "aws_security_group" "EC2_security_group" {
  name        = terraform.workspace == "stg" ? "EC2_security_group_stg" : "EC2_security_group_prod"
  description = "A security group for the EC2 instance"
  vpc_id      = aws_vpc.base_project_VPC.id

  ingress {
    description = "Access from ALB"
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [
      "${aws_security_group.ALB_security_group.id}",
    ]
  }

  ingress {
    description = "Allow SSH from computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_app_ec2_security_group_stg" : "geacco_app_ec2_security_group_prod"
  }
}

resource "aws_key_pair" "geacco_app_kp" {
  key_name   = terraform.workspace == "stg" ? "geacco_app_kp_stg" : "geacco_app_kp_prod"
  public_key = local.EC2_instance_pub_key_secrets.EC2_instance_secret_key_pub
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_instance" "base_project_EC2_instance" {
  count                       = var.settings.web_app.count
  ami                         = data.aws_ami.ecs_ami.id
  instance_type               = var.settings.web_app.instance_type
  subnet_id                   = aws_subnet.base_project_cloud_subnet[count.index].id
  key_name                    = aws_key_pair.geacco_app_kp.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.base_project_repository_intance_profile.name
  vpc_security_group_ids      = [aws_security_group.EC2_security_group.id]

  user_data_base64            = terraform.workspace == "stg" ? filebase64("user_data_stg.sh") : filebase64("user_data.sh")

  # Use this only in creation, not in update
  root_block_device {
    volume_size = 40
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 40
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = 110
  }

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_instance_stg" : "geacco_EC2_instance_prod"
  }
}

resource "aws_eip" "geacco_EC2_eip" {
  count = var.settings.web_app.count

  instance = aws_instance.base_project_EC2_instance[count.index].id

  vpc = true

  tags = {
    Name = terraform.workspace == "stg" ? "geacco_EC2_iep_instance_stg" : "geacco_EC2_iep_instance_prod"
  }
}
