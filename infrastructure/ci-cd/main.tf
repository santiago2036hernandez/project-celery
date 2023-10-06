terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket  = "geacco-app-ci-cd-tfstate"
    key     = "global/s3/geacco_app_ci_cd.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "geacco_app_ci_cd" {
  bucket = "geacco-app-ci-cd-tfstate"
}

resource "aws_s3_bucket_versioning" "geacco_app_ci_cd_versioning" {
  bucket = aws_s3_bucket.geacco_app_ci_cd.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "geacco_app_ci_cd_encryption_configuration" {
  bucket = aws_s3_bucket.geacco_app_ci_cd.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_user" "backend_user" {
  name = "geacco_app_ci_cd-user"
}

resource "aws_iam_access_key" "backend_user_api_access" {
  user = aws_iam_user.backend_user.name
}

resource "aws_iam_user_policy_attachment" "backend_user_attach_policies" {
  count      = length(var.iam_policy_arn_ci_cd_user)
  user       = aws_iam_user.backend_user.name
  policy_arn = var.iam_policy_arn_ci_cd_user[count.index]
}

resource "aws_iam_user_policy" "backend_user_inline_policy" {
  name = "geacco_app_ci_cd-policy"
  user = aws_iam_user.backend_user.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53domains:*",
                "ecr:BatchGetImage",
                "ecr:GetRepositoryPolicy",
                "ecr:SetRepositoryPolicy",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:UploadLayerPart",
                "ecr:GetAuthorizationToken",
                "ecr:ListTagsForResource",
                "ecr:GetLifecyclePolicy",
                "ecr:CreateRepository",
                "ecr:PutLifecyclePolicy",
                "acm:RequestCertificate",
                "acm:DescribeCertificate",
                "acm:ListTagsForCertificate",
                "acm:DeleteCertificate",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeleteRepository"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
