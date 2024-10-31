
#ecr create repository for this project (repositorio for image)
resource "aws_ecr_repository" "ecrrepo" {
  depends_on = [null_resource.iamsetup]
  name                 = var.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#get complete environment
resource "null_resource" "setupcode" {
  depends_on = [
    null_resource.iamsetup,
    aws_s3_object.source_code_zip,
    aws_ecr_repository.ecrrepo,
  ]
  provisioner "local-exec" {
    command = "echo 'Setup complete. Ready to start CodeBuild.'"
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/codebuild/${var.bucket_name}"
  retention_in_days = 14  # A
  depends_on = [
    null_resource.setupcode
  ]
}

resource "aws_codebuild_project" "build_repo" {
  depends_on = [null_resource.setupcode]

  name           = var.codebuild_name
  description    = "CodeBuild project for building and pushing Docker image"
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = "arn:aws:kms:${local.aws_region}:${local.aws_account}:alias/aws/s3"
  build_timeout  = 5
  queued_timeout = 5
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "build_code"
      value = var.build_code
    }

    environment_variable {
      name  = "IMAGE_NAME"
      value = var.image_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT"
      value = local.aws_account
    }

    environment_variable {
      name  = "AWS_REGION"
      value = local.aws_region
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      status              = "DISABLED"
      encryption_disabled = false
    }
  }

  tags = {
    Environment = "Dev"
    Project     = var.codebuild_name
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

 source {
    type      = "S3"
    location  = "${aws_s3_bucket.mybucket.bucket}/code.zip"
    buildspec = local.buildspec_content
    insecure_ssl = false
  }
}

#configure lambda to run the image
resource "aws_lambda_function" "estados" {
  depends_on = [aws_codebuild_project.build_repo]
  function_name     = var.image_name
  package_type      = "Image"
  image_uri        = "${aws_ecr_repository.ecrrepo.repository_url}:latest"  # Referência direta ao ECR
  role              = aws_iam_role.lambda_execution_role.arn
  memory_size       = 512
  timeout           = 900
  architectures     = ["x86_64"]

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      SLACK_TOKEN   = var.slack_token
      SLACK_CHANNEL = var.slack_channel
    }
  }
}