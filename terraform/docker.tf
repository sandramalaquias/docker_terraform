#define bucket code (acl = private by default)
resource "aws_s3_bucket" "mybucket" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
  }
}

# Create a zip file
data "archive_file" "code_zip" {
  type        = "zip"
  output_path = "${var.code_path}/code.zip"

  dynamic "source" {
    for_each = var.source_files
    content {
      content  = file("${var.code_path}/${source.value}")
      filename = source.value
    }
  }
}

# send the zip file to S3
resource "aws_s3_object" "source_code_zip" {
  bucket     = var.bucket_name
  key        = "code.zip"
  source     = data.archive_file.code_zip.output_path
  depends_on = [
    aws_s3_bucket.mybucket
  ]
}

# null_resource para acionar a nova execução do CodeBuild ao detectar mudança no código
resource "null_resource" "code_changed" {
  triggers = {
    code_hash = filebase64sha256("${data.archive_file.code_zip.output_path}")
  }
}
