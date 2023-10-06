resource "aws_secretsmanager_secret" "db_credential" {
   name = terraform.workspace == "stg" ? "stg-database-credential" : "prod-database-credential"
}

data "aws_secretsmanager_secret" "db_credentials" {
  arn = aws_secretsmanager_secret.db_credential.arn
}

data "aws_secretsmanager_secret_version" "db_cred" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.arn
}


resource "aws_secretsmanager_secret" "secret_key" {
   name = terraform.workspace == "stg" ? "stg-secret-key" : "prod-secret-key"
}

data "aws_secretsmanager_secret" "secret_key" {
  arn = aws_secretsmanager_secret.secret_key.arn
}

data "aws_secretsmanager_secret_version" "secret_key" {
  secret_id = data.aws_secretsmanager_secret.secret_key.arn
}

resource "aws_secretsmanager_secret" "EC2_instance_secret_key" {
   name = terraform.workspace == "stg" ? "EC2-instance-secret-key-stg" : "EC2-instance-secret-key-prod"
}

data "aws_secretsmanager_secret" "EC2_instance_pub_key_secret" {
  arn = aws_secretsmanager_secret.EC2_instance_secret_key.arn
}

data "aws_secretsmanager_secret_version" "EC2_instance_pub_key_secret" {
  secret_id = data.aws_secretsmanager_secret.EC2_instance_pub_key_secret.arn
}

resource "aws_secretsmanager_secret" "EC2_instance_ip" {
   name = terraform.workspace == "stg" ? "EC2-instance-ip-stg" : "EC2-instance-ip-prod"
}

data "aws_secretsmanager_secret" "EC2_instance_ip_secret" {
  arn = aws_secretsmanager_secret.EC2_instance_ip.arn
}

data "aws_secretsmanager_secret_version" "EC2_instance_ip_secret" {
  secret_id = data.aws_secretsmanager_secret.EC2_instance_ip_secret.arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_cred.secret_string)
  secret_keys = jsondecode(data.aws_secretsmanager_secret_version.secret_key.secret_string)
  EC2_instance_pub_key_secrets = jsondecode(data.aws_secretsmanager_secret_version.EC2_instance_pub_key_secret.secret_string)
  EC2_instance_ips = jsondecode(data.aws_secretsmanager_secret_version.EC2_instance_ip_secret.secret_string)
}
