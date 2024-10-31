output "ecr_repository_uri" {
  description = "URI do repositório ECR"
  value       = aws_ecr_repository.ecrrepo.repository_url
}

output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = var.bucket_name
}

output "docker_image_tag" {
  description = "Tag imagem Docker"
  value       = var.image_name
}

output "codebuild_role_arn" {
  description = "Role ARN used in CodeBuild"
  value       = aws_iam_role.codebuild_role.arn
}
