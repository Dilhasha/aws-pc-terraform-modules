resource "aws_iam_role" "cd_codebuild_role" {
  name = "cd-${var.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Effect = "Allow"
      },
      {
        Effect = "Allow",
        Principal = {
          "AWS" = var.admin_role
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_eks_access_entry" "codebuild" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.cd_codebuild_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "codebuild" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.cd_codebuild_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

module "cd_codebuild_iam_policy" {
  source      = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/IAM-Policy?ref=UnitOfWork"
  project     = var.project
  environment = var.environment
  region      = var.region
  tags        = var.default_tags
  application = "cd-codebuild"
  policy      = file("${path.module}/resources/cd-codebuild-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "cd_codebuild_iam_policy_attachment" {
  role       = aws_iam_role.cd_codebuild_role.name
  policy_arn = module.cd_codebuild_iam_policy.iam_policy_arn
}

resource "aws_codebuild_project" "cd_project_build" {
  name         = "${var.project}-k8s-deployment"
  description  = "CD project to build common artifacts for Kubernetes deployment"
  service_role = aws_iam_role.cd_codebuild_role.arn

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
    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = module.eks.cluster_name
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # Path in the GitHub repo cloned by Source stage
  }
}

resource "aws_s3_bucket" "cd_codepipeline_bucket" {
  bucket = var.cd_bucket_name
}

resource "aws_codepipeline" "cd_pipeline" {
  name     = "${var.project}-cd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.cd_codepipeline_bucket.bucket
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
        Repo       = var.cd_project_integration_build_repo_name
        Branch     = var.devops_cd_project_build_branch
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
        ProjectName = aws_codebuild_project.cd_project_build.name
      }
    }
  }
}

resource "aws_s3_bucket" "integration_codepipeline_bucket" {
  bucket = var.integration_bucket_name
}

resource "aws_codebuild_project" "integration_project_build" {
  name         = "${var.project}-k8s-integration-deployment"
  description  = "CD project to build integration artifacts for Kubernetes deployment"
  service_role = aws_iam_role.cd_codebuild_role.arn

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
    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = module.eks.cluster_name
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec_integration.yml" # Path in the GitHub repo cloned by Source stage
  }
}

resource "aws_codepipeline" "integration_pipeline" {
  name     = "${var.project}-integration-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.integration_codepipeline_bucket.bucket
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
        Repo       = var.cd_project_integration_build_repo_name
        Branch     = var.devops_cd_project_build_branch
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
        ProjectName = aws_codebuild_project.integration_project_build.name
      }
    }
  }
}
