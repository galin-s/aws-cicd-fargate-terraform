output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}