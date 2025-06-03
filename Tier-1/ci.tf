resource "aws_iam_role" "codebuild_role" {
  name = "${var.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

module "codebuild_iam_policy" {
  source      = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/IAM-Policy?ref=UnitOfWork"
  project     = var.project
  environment = var.environment
  region      = var.region
  tags        = var.default_tags
  application = "codebuild"
  policy      = file("${path.module}/resources/codebuild-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "codebuild_iam_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = module.codebuild_iam_policy.iam_policy_arn
}

resource "aws_codebuild_project" "ci_project_build" {
  name         = "${var.project}-docker-build"
  description  = "CI project to build Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "ECR_REGISTRY_URL"
      value = local.ecr_registry_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # Path in the GitHub repo cloned by Source stage
  }
}

# 5. CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.ci_bucket_name
}

module "codepipeline_iam_policy" {
  source      = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/IAM-Policy?ref=UnitOfWork"
  project     = var.project
  environment = var.environment
  region      = var.region
  tags        = var.default_tags
  application = "s3_management"
  policy      = file("${path.module}/resources/codepipeline-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = module.codepipeline_iam_policy.iam_policy_arn
}

# 6. CodePipeline
resource "aws_codepipeline" "ci_pipeline" {
  name     = "${var.project}-ci-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_org_name
        Repo       = var.ci_project_integration_build_repo_name
        Branch     = var.devops_ci_project_build_branch
        OAuthToken = var.github_personal_access_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ci_project_build.name
      }
      
    }
  }
}
