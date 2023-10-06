# output "base_ecr_ui" {
#   value = module.base_project_ECR.ecr_uri
# }

output "web_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_eip.geacco_EC2_eip[0].public_ip

  depends_on = [aws_eip.geacco_EC2_eip]
}

output "web_public_dns" {
  description = "The public DNS address of the web server"
  value       = aws_eip.geacco_EC2_eip[0].public_dns

  depends_on = [aws_eip.geacco_EC2_eip]
}

output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.geacco_db_instance.address
}

output "database_name" {
  description = "The endpoint of the database"
  value       = aws_db_instance.geacco_db_instance.db_name
}

output "redis_endpoint" {
  description = "The endpoint of redis"
  value       = aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address
}

// This will output the database port
# output "database_port" {
#   description = "The port of the database"
#   value       = aws_db_instance.geacco_db_instance.port
# }
