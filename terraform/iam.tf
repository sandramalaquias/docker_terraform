# Política combinada para ECR, S3, CloudWatch Logs, e Lambda
resource "aws_iam_policy" "combined_policy" {
  name        = "combined-access-policy"
  description = "IAM policy to allow access to ECR, S3, CloudWatch Logs, and Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },

    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "*"
    },

    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },

    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:ListFunctions"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Role para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-estados"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Role para Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role-estados"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# attach a policy combined to CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.combined_policy.arn
}

# attach a policy combined to Lambda role
resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.combined_policy.arn
}

resource "null_resource" "iamsetup" {
  depends_on = [
    aws_iam_policy.combined_policy,
    aws_iam_role.codebuild_role,
    aws_iam_role.lambda_execution_role,
    aws_iam_role_policy_attachment.codebuild,
    aws_iam_role_policy_attachment.lambda,
  ]
  provisioner "local-exec" {
    command = "echo 'Setup IAM. Ready to start CodeBuild.'"
  }
}


