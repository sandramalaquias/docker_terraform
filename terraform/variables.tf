variable "bucket_name" {
 type = string
 default = "docker-estado"
 description = "bucket code for container"
}

variable "slack_token" {
 type = string
 description = "token to send message to slack"
 sensitive   = true
}

variable "slack_channel" {
 type = string
 description = "slack channel to send message to slack"
 sensitive   = true
}

variable "image_name" {
 type = string
 default = "state"
 description = "image name to ECR tag"
}

variable "codebuild_name" {
 type = string
 default = "build-state"
 description = "codebuild project name"
}

#code path
variable "code_path" {
  description = "Path to the code file"
  type        = string
  default     = "/home/sandra/Documents/code/calend/estados/code"
}

#files to zip
variable "source_files" {
  description = "List of files to include in the zip"
  type        = list(string)
  default     = [
    "Dockerfile",
    "estados.py",
    "requirements.txt",
    ".dockerignore"
  ]
}

# Obtain AWS account ID and AWS Region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#Capture the values to specbuild
locals {
  aws_account      = data.aws_caller_identity.current.account_id
  aws_region       = data.aws_region.current.name
  buildspec_content = templatefile("${var.code_path}/buildspec.yml", {
    AWS_ACCOUNT = local.aws_account
    AWS_REGION  = local.aws_region
    SLACK_TOKEN = var.slack_token
    SLACK_CHANNEL = var.slack_channel
    IMAGE_NAME  = var.image_name
  })
}

variable "build_code" {
  type    = number
  default = 3 # Change the value to trigger codebuild rebuild
}

